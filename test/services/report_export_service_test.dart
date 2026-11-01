import 'package:flutter_test/flutter_test.dart';
import 'package:prm323_lab3/models/course_model.dart';
import 'package:prm323_lab3/models/note_model.dart';
import 'package:prm323_lab3/models/task_model.dart';
import 'package:prm323_lab3/services/report_export_service.dart';
import 'package:prm323_lab3/services/report_pdf_service.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/fake_storage_service.dart';
import '../helpers/mock_analytics_service.dart';

void main() {
  // RootBundle-backed font loading needs the binding initialized.
  TestWidgetsFlutterBinding.ensureInitialized();

  final courses = [
    const CourseModel(
      id: 'PRM323',
      code: 'PRM323',
      name: 'Lập trình Di động',
      credits: 3,
      semester: 5,
      major: 'SE',
      completedSlots: 12,
      totalSlots: 30,
      currentGrade: 8.5,
    ),
  ];
  final tasks = [
    const TaskModel(
        id: 't1',
        title: 'Lab 3 checklist',
        courseCode: 'PRM323',
        dueDate: '15/12/2024',
        isCompleted: true),
    const TaskModel(
        id: 't2',
        title: 'Ôn thi final',
        courseCode: 'PRM323',
        dueDate: '20/12/2024'),
  ];
  final notes = [
    const NoteModel(
        id: 'n1',
        title: 'Note Firestore rules',
        content: '...',
        courseCode: 'PRM323',
        updatedAt: '01/11/2026'),
  ];

  group('ReportExportService', () {
    late FakeStorageService storage;
    late FakeFirestoreService firestore;
    late MockAnalyticsService analytics;
    late ReportExportService exporter;

    setUp(() {
      storage = FakeStorageService();
      firestore = FakeFirestoreService();
      analytics = MockAnalyticsService();
      // Real PDF generator — asserts the full production path, fonts included.
      exporter = ReportExportService(
        storageService: storage,
        firestoreService: firestore,
        analyticsService: analytics,
      );
    });

    test('success flow uploads to reports/{uid}/… with PDF content type',
        () async {
      final result = await exporter.exportStudyReport(
        userId: 'uid_123',
        courses: courses,
        tasks: tasks,
        notes: notes,
      );

      expect(storage.uploads, hasLength(1));
      final upload = storage.uploads.single;
      expect(upload['path'], startsWith('reports/uid_123/study_report_'));
      expect(upload['path'], endsWith('.pdf'));
      expect(upload['contentType'], 'application/pdf');
      expect(result.downloadUrl, contains('reports/uid_123'));
      expect(result.bytes, greaterThan(1024));
      expect(result.pdfBytes.length, result.bytes);
    });

    test('progress callback receives upload fractions in order', () async {
      final seen = <double>[];
      await exporter.exportStudyReport(
        userId: 'uid_123',
        courses: courses,
        tasks: tasks,
        notes: notes,
        onProgress: seen.add,
      );
      expect(seen, [0.5, 1.0]);
    });

    test('long uid is used verbatim in the storage path', () async {
      final longUid = 'a-very-long-firebase-uid-0123456789';
      final result = await exporter.exportStudyReport(
        userId: longUid,
        courses: courses,
        tasks: tasks,
        notes: notes,
      );
      expect(result.storagePath, startsWith('reports/$longUid/'));
    });

    test('metadata is persisted to Firestore with counts and URL', () async {
      await exporter.exportStudyReport(
        userId: 'uid_123',
        courses: courses,
        tasks: tasks,
        notes: notes,
      );

      expect(firestore.reports, hasLength(1));
      final meta = firestore.reports.single;
      expect(meta['userId'], 'uid_123');
      expect(meta['courseCount'], 1);
      expect(meta['taskCount'], 2);
      expect(meta['noteCount'], 1);
      expect(meta['downloadUrl'], isA<String>());
      expect(meta['storagePath'], startsWith('reports/uid_123/'));
    });

    test('export_report event fires exactly once with success params',
        () async {
      await exporter.exportStudyReport(
        userId: 'uid_123',
        courses: courses,
        tasks: tasks,
        notes: notes,
      );

      final events = analytics.loggedEvents
          .where((e) => e['name'] == 'export_report')
          .toList();
      expect(events, hasLength(1));
      final params = events.single['parameters'] as Map<String, Object>;
      expect(params['status'], 'success');
      expect(params['file_size_kb'], greaterThan(0));
      expect(params['duration_ms'], isA<int>());
    });

    test('storage failure rethrows and logs export_report=failed', () async {
      storage.shouldFailUpload = true;

      await expectLater(
        exporter.exportStudyReport(
          userId: 'uid_123',
          courses: courses,
          tasks: tasks,
          notes: notes,
        ),
        throwsA(isA<Exception>()),
      );

      final events = analytics.loggedEvents
          .where((e) => e['name'] == 'export_report')
          .toList();
      expect(events, hasLength(1));
      expect((events.single['parameters'] as Map)['status'], 'failed');
      // Metadata must NOT be written when the upload itself failed.
      expect(firestore.reports, isEmpty);
    });

    test('metadata failure also rethrows and marks the event failed',
        () async {
      firestore.shouldFailReportSave = true;

      await expectLater(
        exporter.exportStudyReport(
          userId: 'uid_123',
          courses: courses,
          tasks: tasks,
          notes: notes,
        ),
        throwsA(isA<Exception>()),
      );

      final events = analytics.loggedEvents
          .where((e) => e['name'] == 'export_report')
          .toList();
      expect((events.single['parameters'] as Map)['status'], 'failed');
    });
  });

  group('ReportPdfService (real generator)', () {
    test('produces a valid PDF from real models with Vietnamese content',
        () async {
      final service = ReportPdfService();
      final bytes = await service.buildStudyReport(
        generatedAt: DateTime(2026, 10, 31, 9, 30),
        courses: courses,
        tasks: tasks,
        notes: notes,
        uidHint: '…6789abcd',
      );

      // PDF header + EOF marker prove the document is structurally valid.
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, '%PDF-');
      final tail = String.fromCharCodes(bytes.skip(bytes.length - 6));
      expect(tail.trimRight(), endsWith('%%EOF'));
      expect(bytes.length, greaterThan(1024));
    });

    test('handles empty datasets without crashing', () async {
      final service = ReportPdfService();
      final bytes = await service.buildStudyReport(
        generatedAt: DateTime(2026, 10, 31),
        courses: const [],
        tasks: const [],
        notes: const [],
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
