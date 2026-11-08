import { after, before, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, query, onSnapshot, serverTimestamp, setDoc, updateDoc, where } from 'firebase/firestore';

let env;
const db = (uid) => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const plan = (uid, semester = 1, extra = {}) => ({
  uid, semester, summary: 'Study plan', status: 'pending', reason: '', createdAt: serverTimestamp(), ...extra,
});
const review = (uid, extra = {}) => ({
  status: 'approved', reason: 'Valid plan', reviewedAt: serverTimestamp(), reviewedBy: uid, ...extra,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-second-brain-final',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
  await env.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await Promise.all([
      setDoc(doc(firestore, 'users/student'), { role: 'user' }),
      setDoc(doc(firestore, 'users/peer'), { role: 'user' }),
      setDoc(doc(firestore, 'users/staff'), { role: 'staff' }),
      setDoc(doc(firestore, 'users/admin'), { role: 'admin' }),
      setDoc(doc(firestore, 'users/legacy'), { currentSemester: 4 }),
    ]);
  });
});

after(async () => env?.cleanup());

test('role bootstrap, private profiles, and escalation protection', async () => {
  await assertFails(setDoc(doc(db('new'), 'users/new'), { role: 'admin' }));
  await assertSucceeds(setDoc(doc(db('new'), 'users/new'), { role: 'user' }));
  await assertSucceeds(updateDoc(doc(db('legacy'), 'users/legacy'), { role: 'user' }));
  await assertFails(updateDoc(doc(db('new'), 'users/new'), { role: 'staff' }));
  await assertFails(getDoc(doc(db('staff'), 'users/new')));
  await assertFails(updateDoc(doc(db('staff'), 'users/new'), { role: 'staff' }));
  await assertFails(updateDoc(doc(db('admin'), 'users/admin'), { role: 'staff' }));
  await assertSucceeds(updateDoc(doc(db('admin'), 'users/new'), { role: 'staff' }));
});

test('plans enforce ownership, shape, review and one terminal transition', async () => {
  const path = 'study_plan_submissions/student_1';
  await assertFails(setDoc(doc(db('student'), path), plan('peer')));
  await assertFails(setDoc(doc(db('student'), path), plan('student', 2)));
  await assertFails(setDoc(doc(db('student'), path), plan('student', 1, {status: 'approved'})));
  await assertFails(setDoc(doc(db('student'), path), plan('student', 1, {summary: 'x'.repeat(601)})));
  await assertSucceeds(setDoc(doc(db('student'), path), plan('student')));
  await assertFails(getDoc(doc(db('peer'), path)));
  await assertFails(getDoc(doc(db(), path)));
  await assertSucceeds(getDocs(query(collection(db('student'), 'study_plan_submissions'), where('uid', '==', 'student'))));
  await assertSucceeds(getDoc(doc(db('staff'), path)));
  await assertFails(updateDoc(doc(db('student'), path), review('student')));
  await assertFails(updateDoc(doc(db('staff'), path), review('staff', { uid: 'peer' })));
  await assertFails(updateDoc(doc(db('staff'), path), review('staff', { reason: '' })));
  await assertSucceeds(updateDoc(doc(db('staff'), path), review('staff')));
  await assertFails(updateDoc(doc(db('admin'), path), review('admin', { status: 'rejected' })));
});

test('announcements require privileged author and a valid payload', async () => {
  const payload = { title: 'Schedule', body: 'Check your course', publishedAt: serverTimestamp() };
  const path = 'announcements/demo';
  await assertFails(setDoc(doc(db('student'), path), { ...payload, authorUid: 'student' }));
  await assertFails(setDoc(doc(db('staff'), path), { ...payload, authorUid: 'admin' }));
  await assertSucceeds(setDoc(doc(db('staff'), path), { ...payload, authorUid: 'staff' }));
  await assertFails(getDoc(doc(db(), path)));
  await assertSucceeds(getDoc(doc(db('student'), path)));
  await assertFails(updateDoc(doc(db('staff'), path), { body: 'Changed' }));
});

test('catalog management preserves immutable code and supports archive', async () => {
  const path = 'courses/PRM393';
  const data = { code: 'PRM393', name: 'Mobile Programming', credits: 3, semester: 8, major: 'SE' };
  await assertFails(setDoc(doc(db('student'), path), data));
  await assertSucceeds(setDoc(doc(db('staff'), path), data));
  await assertSucceeds(getDoc(doc(db('student'), path)));
  await assertFails(updateDoc(doc(db('staff'), path), { code: 'PRM999' }));
  await assertSucceeds(updateDoc(doc(db('admin'), path), { archived: true }));
});

test('student listener receives staff decision without a refresh', async () => {
  const path = 'study_plan_submissions/student_3';
  await assertSucceeds(setDoc(doc(db('student'), path), plan('student', 3)));
  const ref = doc(db('student'), path);
  let unsubscribe;
  let timer;
  try {
    await new Promise((resolve, reject) => {
      timer = setTimeout(() => reject(new Error('decision listener timed out')), 10000);
      let reviewed = false;
      unsubscribe = onSnapshot(ref, (snapshot) => {
        if (snapshot.get('status') === 'pending' && !reviewed) {
          reviewed = true;
          assertSucceeds(updateDoc(doc(db('staff'), path), review('staff', {
            status: 'rejected', reason: 'Adjust workload',
          }))).catch(reject);
        }
        if (snapshot.get('status') === 'rejected' && snapshot.get('reason') === 'Adjust workload') {
          resolve();
        }
      }, reject);
    });
  } finally {
    clearTimeout(timer);
    unsubscribe?.();
  }
});
