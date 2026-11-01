import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firestore_service.dart';

/// Cloud Firestore implementation with offline persistence enabled.
class FirebaseFirestoreService implements FirestoreService {
  FirebaseFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _initPersistence();
  }

  final FirebaseFirestore _firestore;

  void _initPersistence() {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('[Firestore] Offline persistence enabled with unlimited cache.');
    } catch (e) {
      debugPrint('[Firestore] Persistence config warning: $e');
    }
  }

  // ──────────────────────── Courses / Roadmap ────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getCourses(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .orderBy('semester')
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('[Firestore] getCourses error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCourse(String courseId) async {
    try {
      final doc = await _firestore
          .collection('courses')
          .doc(courseId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      debugPrint('[Firestore] getCourse error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.serverAndCache));
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      debugPrint('[Firestore] getUserProfile error: $e');
      rethrow;
    }
  }

  // ──────────────────────── Tasks ────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getTasks(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .orderBy('dueDate', descending: false)
          .get(const GetOptions(source: Source.serverAndCache));

      // Prefer the actual Firestore document ID as the canonical task ID.
      // For new documents (T03-M11D fix): doc.data()['id'] == snapshot.id.
      // For legacy documents (old .add()): doc.data()['id'] differs from snapshot.id;
      // we use snapshot.id as the canonical ID and preserve the original data.id
      // as a legacy reference field.
      final doc = snapshot.docs.firstOrNull;
      if (doc == null) return [];

      final data = doc.data();
      final firestoreId = doc.id;
      final dataId = data['id'] as String?;
      final taskId = dataId != null && dataId.isNotEmpty && dataId == firestoreId
          ? firestoreId
          : firestoreId; // always prefer Firestore document ID as canonical

      // Build the map: include the canonical task ID (Firestore document ID)
      // and optionally the original data id as legacyId for legacy documents.
      // We explicitly do NOT spread data['id'] into the result, because that
      // would overwrite the canonical id with the data field id — which is
      // the root cause of the not-found error when legacy documents have a
      // different data.id than the Firestore document ID.
      final result = <String, dynamic>{
        'id': taskId,
        if (dataId != null && dataId != firestoreId) 'legacyId': dataId,
      }..addAll(data..remove('id'));

      return [result];
    } catch (e) {
      debugPrint('[Firestore] getTasks error: $e');
      rethrow;
    }
  }

  @override
  Future<void> addTask(Map<String, dynamic> task) async {
    try {
      final userId = task['userId'] as String?;
      if (userId == null) throw ArgumentError('Task must include userId');

      // Use the app-generated task ID as the Firestore document ID
      // so that updateTask/deleteTask can target the correct document path.
      var taskId = task['id'] as String?;
      if (taskId == null || taskId.isEmpty) {
        // Fallback: generate an ID and use .doc(id).set() if no ID provided
        taskId = DateTime.now().millisecondsSinceEpoch.toString();
      }
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .set({
        ...task,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] addTask error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      final userId = data['userId'] as String?;
      if (userId == null) throw ArgumentError('Update data must include userId');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // DEBUG: Capture FirebaseException details for root-cause analysis.
      // Log only code, message, and stack trace — no credentials, tokens, or sensitive data.
      debugPrint('[Firestore] updateTask FirebaseException: code=${e.code}, message=${e.message}');
      debugPrint('[Firestore] updateTask FirebaseException: stackTrace=${e.stackTrace}');
      rethrow;
    } catch (e) {
      // DEBUG: Capture non-FirebaseException errors.
      debugPrint('[Firestore] updateTask unexpected error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      debugPrint('[Firestore] deleteTask error: $e');
      rethrow;
    }
  }

  // ──────────────────────── Notes ────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getNotes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('[Firestore] getNotes error: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveNote(Map<String, dynamic> note) async {
    try {
      final userId = note['userId'] as String?;
      if (userId == null) throw ArgumentError('Note must include userId');

      final noteId = note['id'] as String?;
      final noteRef = noteId != null && noteId.isNotEmpty
          ? _firestore.collection('users').doc(userId).collection('notes').doc(noteId)
          : _firestore.collection('users').doc(userId).collection('notes').doc();

      await noteRef.set({
        ...note,
        'id': noteRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] saveNote error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNote(String userId, String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      debugPrint('[Firestore] deleteNote error: $e');
      rethrow;
    }
  }

  // ──────────────────────── Report metadata ────────────────────────

  @override
  Future<void> saveReportMetadata(
      String userId, Map<String, dynamic> metadata) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sync')
          .doc('report_${DateTime.now().millisecondsSinceEpoch}')
          .set({
        ...metadata,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[Firestore] Saved report metadata for $userId');
    } catch (e) {
      debugPrint('[Firestore] saveReportMetadata error: $e');
      rethrow;
    }
  }

  // ──────────────────────── Notification Center ────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('receivedAt', descending: true)
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('[Firestore] getNotifications error: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveNotification(
      String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        ...data,
        'receivedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firestore] saveNotification error: $e');
      rethrow;
    }
  }

  @override
  Future<void> markNotificationRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('[Firestore] markNotificationRead error: $e');
      rethrow;
    }
  }

  @override
  Future<void> registerToken(String userId, String token) async {
    try {
      // Deterministic doc id (hash of token) keeps one row per device token.
      final tokenId = token.length > 24
          ? token.substring(0, 24)
          : token;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(tokenId)
          .set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[Firestore] Registered FCM token for $userId');
    } catch (e) {
      debugPrint('[Firestore] registerToken error: $e');
      rethrow;
    }
  }
}
