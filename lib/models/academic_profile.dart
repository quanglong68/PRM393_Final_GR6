/// User-entered academic records. Missing records stay missing; course catalog
/// defaults and simulation sliders are never treated as a transcript.
class TranscriptEntry {
  const TranscriptEntry({
    required this.courseCode,
    required this.credits,
    required this.grade,
    required this.semester,
    required this.passed,
  });
  final String courseCode;
  final int credits;
  final double grade;
  final int semester;
  final bool passed;

  factory TranscriptEntry.fromMap(Map<String, dynamic> map) => TranscriptEntry(
    courseCode: map['courseCode'] as String,
    credits: (map['credits'] as num).toInt(),
    grade: (map['grade'] as num).toDouble(),
    semester: (map['semester'] as num).toInt(),
    passed: map['passed'] as bool,
  );
  Map<String, dynamic> toMap() => {
    'courseCode': courseCode,
    'credits': credits,
    'grade': grade,
    'semester': semester,
    'passed': passed,
  };
}

class TimetableEntry {
  const TimetableEntry({
    required this.courseCode,
    required this.weekday,
    required this.startSlot,
    required this.slotCount,
  });
  final String courseCode;

  /// ISO weekday: Monday=1, Sunday=7.
  final int weekday;
  final int startSlot;
  final int slotCount;
  int get endSlot => startSlot + slotCount - 1;
  bool overlaps(TimetableEntry other) =>
      weekday == other.weekday &&
      startSlot <= other.endSlot &&
      other.startSlot <= endSlot;

  factory TimetableEntry.fromMap(Map<String, dynamic> map) => TimetableEntry(
    courseCode: map['courseCode'] as String,
    weekday: (map['weekday'] as num).toInt(),
    startSlot: (map['startSlot'] as num).toInt(),
    slotCount: (map['slotCount'] as num).toInt(),
  );
  Map<String, dynamic> toMap() => {
    'courseCode': courseCode,
    'weekday': weekday,
    'startSlot': startSlot,
    'slotCount': slotCount,
  };
}

class AcademicProfile {
  const AcademicProfile({
    this.transcript = const [],
    this.timetable = const [],
    this.passedCourses = const {},
    this.currentSemester,
    this.targetGpa = 8,
  });
  final List<TranscriptEntry> transcript;
  final List<TimetableEntry> timetable;
  final Set<String> passedCourses;
  final int? currentSemester;

  /// Personal planning target, not a university classification rule.
  final double targetGpa;

  factory AcademicProfile.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    return AcademicProfile(
      transcript: (map['transcript'] as List? ?? const [])
          .map(
            (e) => TranscriptEntry.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      timetable: (map['timetable'] as List? ?? const [])
          .map(
            (e) => TimetableEntry.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      passedCourses: (map['passedCourses'] as List? ?? const [])
          .map((e) => e.toString())
          .toSet(),
      currentSemester: (map['currentSemester'] as num?)?.toInt(),
      targetGpa: (map['targetGpa'] as num?)?.toDouble() ?? 8,
    );
  }

  double? get cumulativeGpa {
    if (transcript.isEmpty) return null;
    final credits = transcript.fold<int>(
      0,
      (sum, entry) => sum + entry.credits,
    );
    if (credits == 0) return null;
    return transcript.fold<double>(
          0,
          (sum, entry) => sum + entry.grade * entry.credits,
        ) /
        credits;
  }

  Set<String> get completedCodes => {
    ...passedCourses.where(
      (code) => !transcript.any((entry) => entry.courseCode == code),
    ),
    ...transcript
        .where((entry) => entry.passed)
        .map((entry) => entry.courseCode),
  };
}
