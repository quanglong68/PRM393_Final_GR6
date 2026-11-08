import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

class StudyPlanDraft {
  const StudyPlanDraft(this.goal, this.actions);

  factory StudyPlanDraft.fromJson(String json) {
    final data = jsonDecode(json);
    if (data is! Map<String, dynamic> ||
        data['goal'] is! String ||
        data['actions'] is! List) {
      throw const FormatException('Invalid study plan');
    }
    final goal = (data['goal'] as String).trim();
    final actions = data['actions'] as List;
    if (goal.isEmpty ||
        goal.length > 120 ||
        actions.isEmpty ||
        actions.length > 4 ||
        actions.any(
          (item) => item is! String || item.trim().isEmpty || item.length > 100,
        )) {
      throw const FormatException('Invalid study plan fields');
    }
    return StudyPlanDraft(goal, actions.cast<String>());
  }

  final String goal;
  final List<String> actions;

  String get editableText =>
      [goal, ...actions.map((item) => '• $item')].join('\n');
}

Future<StudyPlanDraft> generateStudyPlan({
  required int semester,
  required String model,
  required String prompt,
}) async {
  if (semester < 1 || semester > 12) throw ArgumentError.value(semester);
  final generator = FirebaseAI.googleAI().generativeModel(
    model: model,
    systemInstruction: Content.system(prompt),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: Schema.object(
        properties: {
          'goal': Schema.string(),
          'actions': Schema.array(items: Schema.string()),
        },
      ),
    ),
  );
  final result = await generator
      .generateContent([
        Content.text('Kỳ học: $semester. Trả lời bằng tiếng Việt.'),
      ])
      .timeout(const Duration(seconds: 25));
  return StudyPlanDraft.fromJson(result.text ?? '');
}
