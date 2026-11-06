import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.courseCode,
    required this.updatedAt,
    this.attachmentUrl,
    this.attachmentPath,
    this.attachmentName,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String content;
  final String courseCode;
  final String updatedAt;
  final String? attachmentUrl;
  final String? attachmentPath;
  final String? attachmentName;
  final List<String> tags;

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? courseCode,
    String? updatedAt,
    String? attachmentUrl,
    String? attachmentPath,
    String? attachmentName,
    List<String>? tags,
  }) => NoteModel(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    courseCode: courseCode ?? this.courseCode,
    updatedAt: updatedAt ?? this.updatedAt,
    attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    attachmentPath: attachmentPath ?? this.attachmentPath,
    attachmentName: attachmentName ?? this.attachmentName,
    tags: tags ?? this.tags,
  );

  factory NoteModel.fromMap(Map<String, dynamic> map) => NoteModel(
    id: map['id'] as String? ?? '',
    title: map['title'] as String? ?? '',
    content: map['content'] as String? ?? '',
    courseCode:
        map['courseCode'] as String? ?? map['courseId'] as String? ?? 'Chung',
    updatedAt: _formatUpdatedAt(map['updatedAt']),
    attachmentUrl: map['attachmentUrl'] as String?,
    attachmentPath: map['attachmentPath'] as String?,
    attachmentName: map['attachmentName'] as String?,
    tags:
        (map['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
        const [],
  );

  static String _formatUpdatedAt(Object? value) {
    if (value is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate());
    }
    if (value is DateTime) {
      return DateFormat('dd/MM/yyyy HH:mm').format(value);
    }
    return value as String? ?? 'Vừa xong';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'courseCode': courseCode,
    'updatedAt': updatedAt,
    'attachmentUrl': attachmentUrl,
    'attachmentPath': attachmentPath,
    'attachmentName': attachmentName,
    'tags': tags,
  };
}
