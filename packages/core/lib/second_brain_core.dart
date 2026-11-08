import 'package:cloud_firestore/cloud_firestore.dart';

class StudyPlanSubmission {
  StudyPlanSubmission.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc)
    : semester = doc.get('semester') as int,
      summary = doc.get('summary') as String,
      status = doc.get('status') as String,
      reason = doc.get('reason') as String;

  final int semester;
  final String summary;
  final String status;
  final String reason;
}

class Announcement {
  Announcement.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc)
    : title = doc.get('title') as String,
      body = doc.get('body') as String;

  final String title;
  final String body;
}

class FinalFirestore {
  FinalFirestore(this.firestore);

  final FirebaseFirestore firestore;

  Stream<List<StudyPlanSubmission>> watchSubmissions(String uid) => firestore
      .collection('study_plan_submissions')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map(StudyPlanSubmission.fromDocument)
            .toList();
        records.sort((a, b) => b.semester.compareTo(a.semester));
        return records;
      });

  Future<void> submit(String uid, int semester, String summary) => firestore
      .collection('study_plan_submissions')
      .doc('${uid}_$semester')
      .set({
        'uid': uid,
        'semester': semester,
        'summary': summary,
        'status': 'pending',
        'reason': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<List<Announcement>> watchAnnouncements() => firestore
      .collection('announcements')
      .orderBy('publishedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Announcement.fromDocument).toList());

  Future<String> ensureRole(String uid) =>
      firestore.runTransaction((transaction) async {
        final ref = firestore.collection('users').doc(uid);
        final snapshot = await transaction.get(ref);
        final role = snapshot.data()?['role'];
        if (role is String) return role;
        transaction.set(ref, {'role': 'user'}, SetOptions(merge: true));
        return 'user';
      });
}
