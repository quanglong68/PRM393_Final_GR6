import 'package:flutter_test/flutter_test.dart';
import 'package:prm323_lab3/viewmodels/advisor_viewmodel.dart';
import 'package:prm323_lab3/viewmodels/academic_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_auth_service.dart';

void main() {
  group('AdvisorViewModel & GPA Strategy Simulator Tests', () {
    late AdvisorViewModel viewModel;

    setUp(() async {
      final auth = MockAuthService(initialUserId: 'test-owner');
      final store = FakeFirestoreService()
        ..courses.addAll([
          {
            'id': 'SWP391',
            'code': 'SWP391',
            'name': 'Test project',
            'credits': 5,
            'semester': 5,
            'major': 'SE',
          },
          {
            'id': 'PRM323',
            'code': 'PRM323',
            'name': 'Test mobile',
            'credits': 3,
            'semester': 5,
            'major': 'SE',
          },
        ]);
      final academic = AcademicViewModel(
        authService: auth,
        firestoreService: store,
      );
      await academic.loadData();
      viewModel = AdvisorViewModel(academicViewModel: academic);
      addTearDown(auth.dispose);
      addTearDown(academic.dispose);
      addTearDown(viewModel.dispose);
    });

    test('Initializes with default Semester 5 assumptions', () {
      expect(viewModel.prmScore, equals(8.5));
      expect(viewModel.swpScore, equals(8.0));
      expect(viewModel.swrScore, equals(8.0));
      expect(viewModel.messages.isNotEmpty, isTrue);
    });

    test('Calculates simulated semester GPA accurately', () {
      // Semester 5 credits: PRM (3), SWP (5), SWR (3) -> total 11
      // Weighted points: 8.5*3 + 8.0*5 + 8.0*3 = 25.5 + 40.0 + 24.0 = 89.5
      // Semester GPA = 89.5 / 11 = 8.136...
      expect(viewModel.predictedSemesterGpa, closeTo(8.136, 0.01));
    });

    test('Evaluates Honors target (>= 8.0) from simulated term GPA', () {
      // Production contract (commit 89405be): the sandbox compares the
      // simulated TERM GPA against the honors threshold directly — a real
      // cumulative GPA comes from the transcript, which this build does not
      // fabricate (see AdvisorViewModel.reachesHonorsTarget).
      // Below threshold: PRM 8.0, SWP 7.5, SWR 7.5
      viewModel.updateSimulation(prm: 8.0, swp: 7.5, swr: 7.5);
      // Weighted: 8.0*3 + 7.5*5 + 7.5*3 = 24.0 + 37.5 + 22.5 = 84.0
      // Term GPA: 84.0 / 11 = 7.636... (< 8.0)
      expect(viewModel.predictedSemesterGpa, lessThan(8.0));
      expect(viewModel.reachesHonorsTarget, isFalse);

      // Improve scores: PRM = 9.0, SWP = 8.5, SWR = 8.5
      viewModel.updateSimulation(prm: 9.0, swp: 8.5, swr: 8.5);

      // Weighted: 9.0*3 + 8.5*5 + 8.5*3 = 27.0 + 42.5 + 25.5 = 95.0
      // Term GPA: 95.0 / 11 = 8.636 (>= 8.0)
      expect(viewModel.predictedSemesterGpa, greaterThanOrEqualTo(8.0));
      expect(viewModel.reachesHonorsTarget, isTrue);
    });

    test('Generates specialized advice for SWP391 keyword queries', () async {
      viewModel.grantConsent();
      await viewModel.askQuestion('Chiến lược học môn SWP391 thế nào?');

      expect(viewModel.messages.length, greaterThanOrEqualTo(2));
      final lastMsg = viewModel.messages.last;
      expect(lastMsg.sender, equals('ai'));
      expect(lastMsg.text, contains('SWP391'));
      // 5 credits — highest weight in Semester 5; strategy copy mentions it.
      expect(lastMsg.text, contains('tín chỉ'));
    });

    test('Exposes the four rubric §6.4 consultation levels', () {
      expect(
        AdvisorLevel.values.map((l) => l.id),
        containsAll(<String>['course', 'semester', 'program', 'score']),
      );
      expect(AdvisorLevel.fromId('score'), AdvisorLevel.score);
      // Unknown/missing slug falls back to course rather than throwing.
      expect(AdvisorLevel.fromId('nope'), AdvisorLevel.course);
      expect(AdvisorLevel.fromId(null), AdvisorLevel.course);
    });

    test('Each level produces a distinct answer', () async {
      viewModel.grantConsent();
      final answers = <String>{};
      for (final level in AdvisorLevel.values) {
        await viewModel.askQuestion('Tư vấn cho tôi', level: level);
        answers.add(viewModel.messages.last.text);
        expect(viewModel.messages.last.level, level);
      }
      expect(answers.length, AdvisorLevel.values.length);
    });

    test(
      'Without consent no question is sent and no bubble is added',
      () async {
        final before = viewModel.messages.length;
        await viewModel.askQuestion('Chiến lược SWP391?');
        expect(viewModel.messages.length, before);
        expect(viewModel.hasConsent, isFalse);
        expect(viewModel.isLoading, isFalse);
      },
    );

    test('grantConsent unlocks asking and is idempotent', () async {
      viewModel.grantConsent();
      viewModel.grantConsent();
      expect(viewModel.hasConsent, isTrue);
      await viewModel.askQuestion('Chiến lược SWP391?');
      expect(viewModel.messages.last.sender, 'ai');
    });

    test('selectLevel drives the default level of the next question', () async {
      viewModel.grantConsent();
      viewModel.selectLevel(AdvisorLevel.score);
      await viewModel.askQuestion('GPA của tôi?');
      expect(viewModel.messages.last.level, AdvisorLevel.score);
      expect(viewModel.selectedLevel, AdvisorLevel.score);
    });
  });
}
