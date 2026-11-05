import { randomUUID } from 'node:crypto';
import { firebaseRequest, FirebaseApiError, projectId } from './firebase-api.mjs';

async function main() {
  const args = process.argv.slice(2);
  const [uid, courseId, mode] = args;
  if (args.length < 2 || args.length > 3 || !/^[A-Za-z0-9_-]{1,128}$/.test(uid) ||
      !/^[A-Za-z0-9_-]{1,50}$/.test(courseId) || (mode && mode !== '--send')) {
    throw new Error('Dùng: npm run send:fcm -- UID COURSE_ID [--send]. Mặc định chỉ validate.');
  }
  const project = projectId();
  const listUrl = new URL(`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/users/${uid}/tokens`);
  listUrl.searchParams.set('orderBy', 'updatedAt desc');
  listUrl.searchParams.set('pageSize', '1');
  listUrl.searchParams.set('mask.fieldPaths', 'token');
  listUrl.searchParams.append('mask.fieldPaths', 'updatedAt');
  const { documents } = await firebaseRequest(listUrl);
  const registration = documents?.[0]?.fields;
  const token = registration?.token?.stringValue;
  const updatedAt = Date.parse(registration?.updatedAt?.timestampValue ?? '');
  if (!token || !Number.isFinite(updatedAt) || Date.now() - updatedAt > 86400000) {
    throw new Error('Không có token cập nhật trong 24 giờ. Mở app trên thiết bị đích rồi thử lại.');
  }
  const notificationId = `lab3-${randomUUID()}`;
  const result = await firebaseRequest(`https://fcm.googleapis.com/v1/projects/${project}/messages:send`, {
    method: 'POST',
    body: {
      validate_only: mode !== '--send',
      message: {
        token,
        notification: { title: `Lab 3 · ${courseId}`, body: 'Chạm để xem chi tiết môn học.' },
        data: { notificationId, type: 'system', route: '/course-detail', courseId },
        android: { priority: 'high' },
      },
    },
  });
  console.log(JSON.stringify({
    mode: mode === '--send' ? 'sent' : 'validated',
    message: result.name,
    notificationId,
  }));
}

main().catch((error) => {
  console.error(error instanceof FirebaseApiError ? error.message :
    error.message?.startsWith('Dùng:') || error.message?.startsWith('Không có token') ? error.message :
      'Không gửi được. Kiểm tra Firebase OAuth, IAM và cấu hình project.');
  process.exitCode = 1;
});
