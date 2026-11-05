class CourseLab {
  const CourseLab({
    required this.id,
    required this.title,
    required this.deadline,
    this.score,
    this.status = 'pending', // 'submitted', 'graded', 'pending'
    this.weight,
  });

  final String id;
  final String title;
  final String deadline;
  final double? score;
  final String status;
  final double? weight;

  factory CourseLab.fromMap(Map<String, dynamic> map) => CourseLab(
    id: map['id'] as String? ?? '',
    title: map['title'] as String? ?? '',
    deadline: map['deadline'] as String? ?? '',
    score: (map['score'] as num?)?.toDouble(),
    status: map['status'] as String? ?? 'pending',
    weight: (map['weight'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'deadline': deadline,
    'score': score,
    'status': status,
    if (weight != null) 'weight': weight,
  };
}

class CourseSlot {
  const CourseSlot({
    required this.number,
    required this.title,
    this.date = '',
    this.room = '',
  });
  final int number;
  final String title;
  final String date;
  final String room;
  factory CourseSlot.fromMap(Map<String, dynamic> map) => CourseSlot(
    number: (map['number'] as num?)?.toInt() ?? 0,
    title: map['title'] as String? ?? '',
    date: map['date'] as String? ?? '',
    room: map['room'] as String? ?? '',
  );
  Map<String, dynamic> toMap() => {
    'number': number,
    'title': title,
    'date': date,
    'room': room,
  };
}

class CourseModel {
  const CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.semester,
    required this.major,
    this.prerequisites = const [],
    this.totalSlots = 0,
    this.completedSlots = 0,
    this.currentGrade,
    this.status = 'enrolled',
    this.lecturer = '',
    this.labs = const [],
    this.slots = const [],
    this.overview = '',
  });

  final String id;
  final String code;
  final String name;
  final int credits;
  final int semester;
  final String major;
  final List<String> prerequisites;
  final int totalSlots;
  final int completedSlots;
  final double? currentGrade;
  final String status;
  final String lecturer;
  final List<CourseLab> labs;
  final List<CourseSlot> slots;
  final String overview;

  double get progress => totalSlots > 0 ? completedSlots / totalSlots : 0.0;

  factory CourseModel.fromMap(Map<String, dynamic> map) => CourseModel(
    id: map['id'] as String? ?? map['code'] as String? ?? '',
    code: map['code'] as String? ?? '',
    name: map['name'] as String? ?? '',
    credits: (map['credits'] as num?)?.toInt() ?? 0,
    semester: (map['semester'] as num?)?.toInt() ?? 0,
    major: map['major'] as String? ?? '',
    prerequisites:
        (map['prerequisites'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    totalSlots:
        (map['totalSlots'] as num?)?.toInt() ??
        (map['syllabus']?['totalSlots'] as num?)?.toInt() ??
        0,
    completedSlots:
        (map['completedSlots'] as num?)?.toInt() ??
        (map['syllabus']?['completedSlots'] as num?)?.toInt() ??
        0,
    currentGrade: (map['currentGrade'] as num?)?.toDouble(),
    status: map['status'] as String? ?? 'enrolled',
    lecturer: map['lecturer'] as String? ?? '',
    overview: map['overview'] as String? ?? '',
    slots:
        ((map['slots'] ?? map['syllabus']?['slots']) as List<dynamic>?)
            ?.map(
              (slot) =>
                  CourseSlot.fromMap(Map<String, dynamic>.from(slot as Map)),
            )
            .toList() ??
        const [],
    labs:
        (map['labs'] as List<dynamic>?)
            ?.map((l) => CourseLab.fromMap(l as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'code': code,
    'name': name,
    'credits': credits,
    'semester': semester,
    'major': major,
    'prerequisites': prerequisites,
    'totalSlots': totalSlots,
    'completedSlots': completedSlots,
    'currentGrade': currentGrade,
    'status': status,
    'lecturer': lecturer,
    'labs': labs.map((l) => l.toMap()).toList(),
    'slots': slots.map((slot) => slot.toMap()).toList(),
    'overview': overview,
  };
}
