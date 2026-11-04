import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// A Notification Center entry (Lab 3 T12 — FCM + Notification Center).
///
/// Mirrors documents at `users/{uid}/notifications/{id}`. [receivedAt] is a
/// display string: the service stores `FieldValue.serverTimestamp()`, so parsing
/// must accept `Timestamp`, `DateTime` and legacy `String` (same rule as
/// [NoteModel._formatUpdatedAt]). A plain `as String?` cast crashed the whole
/// center as soon as a notification had been persisted.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'system',
    this.read = false,
    this.receivedAt = '',
    this.route,
  });

  final String id;
  final String title;
  final String body;

  /// 'task_due' | 'sync' | 'advisor' | 'system'
  final String type;
  final bool read;
  final String receivedAt;

  /// In-app destination of the push (`/advisor`, `/sync-vault`, …). Null when
  /// the sender did not address a screen — tapping then only marks read.
  final String? route;

  bool get isUnread => !read;

  factory NotificationModel.fromMap(Map<String, dynamic> map) =>
      NotificationModel(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        type: map['type'] as String? ?? 'system',
        read: map['read'] as bool? ?? false,
        receivedAt: _formatReceivedAt(map['receivedAt']),
        route: map['route'] as String?,
      );

  static String _formatReceivedAt(Object? value) {
    if (value is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate());
    }
    if (value is DateTime) {
      return DateFormat('dd/MM/yyyy HH:mm').format(value);
    }
    // ISO-8601 strings (FCM payloads) render in the same format as Firestore
    // timestamps; already-formatted legacy strings fall through untouched.
    final raw = value as String? ?? '';
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? raw : DateFormat('dd/MM/yyyy HH:mm').format(parsed);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'read': read,
        'receivedAt': receivedAt,
        if (route != null) 'route': route,
      };

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        type: type,
        read: read ?? this.read,
        receivedAt: receivedAt,
        route: route,
      );

  /// Firebase Cloud Messaging payloads carry `title`/`body` plus custom data.
  /// [notificationId] (when present) is the Firestore document id used to mark
  /// the entry read after the user taps it.
  factory NotificationModel.fromPush(
    Map<String, dynamic> payload, {
    String? fallbackId,
  }) {
    final data = payload['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final id = map['notificationId'] as String? ??
        payload['notificationId'] as String? ??
        fallbackId ??
        'local_${DateTime.now().microsecondsSinceEpoch}';
    final parsedTs = _formatReceivedAt(map['receivedAt']);
    final ts = parsedTs.isEmpty ? DateTime.now().toIso8601String() : parsedTs;
    return NotificationModel(
      id: id,
      title: payload['title'] as String? ?? map['title'] as String? ?? '',
      body: payload['body'] as String? ?? map['body'] as String? ?? '',
      type: map['type'] as String? ?? payload['type'] as String? ?? 'system',
      read: false,
      receivedAt: ts,
      route: map['route'] as String? ?? payload['route'] as String?,
    );
  }
}
