import 'dart:async';

import '../models/academic_profile.dart';
import '../models/app_state.dart';
import '../models/course_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'base_viewmodel.dart';

class AcademicViewModel extends BaseViewModel<AcademicProfile> {
  AcademicViewModel({
    required this.authService,
    required this.firestoreService,
  }) {
    _authSub = authService.authStateChanges.listen((_) {
      if (_loadedUid != authService.currentUserId) {
        _plannedGrades.clear();
        _selectedSemester = null;
        _saving = false;
        _profile = const AcademicProfile();
        _courses = [];
        loadData();
      }
    });
    loadData();
  }
  final AuthService authService;
  final FirestoreService firestoreService;
  StreamSubscription<bool>? _authSub;
  String? _loadedUid;
  int _version = 0;
  bool _saving = false;
  AcademicProfile _profile = const AcademicProfile();
  List<CourseModel> _courses = [];
  final Map<String, double> _plannedGrades = {};
  AcademicProfile get profile => _profile;
  List<CourseModel> get courses => List.unmodifiable(_courses);
  bool get isSaving => _saving;
  List<CourseModel> get semesterCourses =>
      _courses.where((c) => c.semester == selectedSemester).toList();
  int? _selectedSemester;
  int? get selectedSemester =>
      _selectedSemester ??
      _profile.currentSemester ??
      (_courses.isEmpty
          ? null
          : _courses.map((c) => c.semester).reduce((a, b) => a > b ? a : b));
  List<int> get semesters =>
      _courses.map((c) => c.semester).toSet().toList()..sort();
  void selectSemester(int value) {
    _selectedSemester = value;
    notifyListeners();
  }

  double? plannedGrade(String courseCode) => _plannedGrades[courseCode];
  void setPlannedGrade(String courseCode, double? grade) {
    if (grade == null) {
      _plannedGrades.remove(courseCode);
    } else {
      _plannedGrades[courseCode] = grade.clamp(0, 10);
    }
    notifyListeners();
  }

  List<CourseModel> get plannedCourses =>
      semesterCourses.where((c) => _plannedGrades.containsKey(c.code)).toList();
  int get plannedCredits => plannedCourses.fold(0, (sum, c) => sum + c.credits);
  double? get plannedGpa => plannedCredits == 0
      ? null
      : plannedCourses.fold<double>(
              0,
              (sum, c) => sum + _plannedGrades[c.code]! * c.credits,
            ) /
            plannedCredits;

  List<String> missingPrerequisites(CourseModel course) => course.prerequisites
      .where((code) => !_profile.completedCodes.contains(code))
      .toList();
  bool isRetake(CourseModel course) =>
      _profile.transcript.any(
        (entry) => entry.courseCode == course.code && !entry.passed,
      ) &&
      !_profile.completedCodes.contains(course.code);
  List<String> get conflicts {
    final codes = plannedCourses.map((c) => c.code).toSet();
    final entries = _profile.timetable
        .where((e) => codes.contains(e.courseCode))
        .toList();
    return [
      for (var i = 0; i < entries.length; i++)
        for (var j = i + 1; j < entries.length; j++)
          if (entries[i].courseCode != entries[j].courseCode &&
              entries[i].overlaps(entries[j]))
            '${entries[i].courseCode} / ${entries[j].courseCode}: thứ ${entries[i].weekday + 1}, slot ${entries[i].startSlot}–${entries[i].endSlot}',
    ];
  }

  @override
  Future<void> loadData() async {
    final version = ++_version;
    final uid = authService.currentUserId;
    _loadedUid = uid;
    setState(const AsyncViewState.loading());
    if (uid == null) {
      _profile = const AcademicProfile();
      _courses = [];
      setState(const AsyncViewState.empty());
      return;
    }
    try {
      final profile = await firestoreService.getUserProfile(uid);
      final courses = await firestoreService.getCourses(uid);
      if (isDisposed ||
          version != _version ||
          uid != authService.currentUserId) {
        return;
      }
      _profile = AcademicProfile.fromMap(profile);
      _courses = courses.map(CourseModel.fromMap).toList();
      setState(AsyncViewState.data(_profile));
    } catch (e) {
      if (isDisposed ||
          version != _version ||
          uid != authService.currentUserId) {
        return;
      }
      setState(
        const AsyncViewState.error(
          'Không tải được dữ liệu học tập. Kiểm tra kết nối và thử lại.',
        ),
      );
    }
  }

  /// Format is explicit and validation happens before any Firestore mutation.
  /// Each transcript row: code,credits,grade,semester,passed(true/false).
  static List<TranscriptEntry> parseTranscript(String input) {
    final result = <TranscriptEntry>[];
    final seen = <String>{};
    for (final row
        in input.split('\n').where((line) => line.trim().isNotEmpty)) {
      final p = row.split(',').map((s) => s.trim()).toList();
      if (p.length != 5) {
        throw const FormatException(
          'Bảng điểm: mỗi dòng cần mã môn,tín chỉ,điểm,kỳ,đã qua(true/false).',
        );
      }
      final credits = int.tryParse(p[1]);
      final grade = double.tryParse(p[2]);
      final semester = int.tryParse(p[3]);
      if (p[0].isEmpty ||
          credits == null ||
          credits <= 0 ||
          grade == null ||
          !grade.isFinite ||
          grade < 0 ||
          grade > 10 ||
          semester == null ||
          semester <= 0 ||
          !['true', 'false'].contains(p[4].toLowerCase())) {
        throw const FormatException(
          'Bảng điểm có giá trị không hợp lệ. Điểm 0–10, tín chỉ/kỳ là số nguyên dương.',
        );
      }
      if (!seen.add(p[0].toUpperCase())) {
        throw const FormatException(
          'Mỗi môn chỉ nhập một kết quả hiện hành; xử lý học lại theo bảng điểm chính thức.',
        );
      }
      result.add(
        TranscriptEntry(
          courseCode: p[0].toUpperCase(),
          credits: credits,
          grade: grade,
          semester: semester,
          passed: p[4].toLowerCase() == 'true',
        ),
      );
    }
    return result;
  }

  /// Each timetable row: code,ISO weekday,startSlot,slotCount.
  static List<TimetableEntry> parseTimetable(String input) {
    return input.split('\n').where((line) => line.trim().isNotEmpty).map((row) {
      final p = row.split(',').map((s) => s.trim()).toList();
      if (p.length != 4) {
        throw const FormatException(
          'Lịch học: mã môn,thứ ISO(1=T2…7=CN),slot đầu,số slot.',
        );
      }
      final day = int.tryParse(p[1]);
      final start = int.tryParse(p[2]);
      final count = int.tryParse(p[3]);
      if (p[0].isEmpty ||
          day == null ||
          day < 1 ||
          day > 7 ||
          start == null ||
          start < 1 ||
          count == null ||
          count < 1) {
        throw const FormatException(
          'Lịch học không hợp lệ. Thứ ISO 1–7; slot và số slot là số nguyên dương.',
        );
      }
      return TimetableEntry(
        courseCode: p[0].toUpperCase(),
        weekday: day,
        startSlot: start,
        slotCount: count,
      );
    }).toList();
  }

  String get transcriptText => _profile.transcript
      .map(
        (e) =>
            '${e.courseCode},${e.credits},${e.grade},${e.semester},${e.passed}',
      )
      .join('\n');
  String get timetableText => _profile.timetable
      .map((e) => '${e.courseCode},${e.weekday},${e.startSlot},${e.slotCount}')
      .join('\n');

  Future<bool> save({
    required String transcript,
    required String timetable,
    required int semester,
    required double targetGpa,
  }) async {
    if (_saving) return false;
    final uid = authService.currentUserId;
    if (uid == null) {
      setLastError('Chưa đăng nhập.');
      return false;
    }
    try {
      final grades = parseTranscript(transcript);
      final schedule = parseTimetable(timetable);
      if (semester < 1 ||
          !targetGpa.isFinite ||
          targetGpa < 0 ||
          targetGpa > 10) {
        throw const FormatException('Kỳ học hoặc mục tiêu GPA không hợp lệ.');
      }
      _saving = true;
      clearLastError();
      notifyListeners();
      await firestoreService.saveAcademicProfile(uid, {
        'transcript': grades.map((e) => e.toMap()).toList(),
        'timetable': schedule.map((e) => e.toMap()).toList(),
        'currentSemester': semester,
        'targetGpa': targetGpa,
        'academicDataSource': 'user_entered',
      });
      if (isDisposed || uid != authService.currentUserId) return false;
      _selectedSemester = semester;
      await loadData();
      return state.state == ViewState.data;
    } on FormatException catch (e) {
      setLastError(e.message);
      return false;
    } catch (e) {
      if (uid == authService.currentUserId) {
        setLastError('Không lưu được dữ liệu. Kiểm tra kết nối và thử lại.');
      }
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _version++;
    _authSub?.cancel();
    super.dispose();
  }
}
