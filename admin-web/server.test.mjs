import assert from 'node:assert/strict';
import { once } from 'node:events';
import test from 'node:test';
import { createAdminServer } from './server.mjs';
import { createMediaServer } from './media-server.mjs';

async function start(server, context) {
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  context.after(() => new Promise((resolve) => server.close(resolve)));
  return `http://127.0.0.1:${server.address().port}`;
}

test('admin auth protects HTML and reports, and validates report period', async (context) => {
  const password = 'local-test-password-2026-only';
  const server = createAdminServer({
    password,
    readReport: async (days) => ({ days, issues: [] }),
  });
  const base = await start(server, context);
  for (const path of ['/', '/api/crashes']) {
    assert.equal((await fetch(base + path)).status, 401);
  }
  const headers = { authorization: 'Basic ' + Buffer.from('admin:' + password).toString('base64') };
  assert.equal((await fetch(base + '/', { headers })).status, 200);
  assert.equal((await fetch(base + '/api/crashes?days=365', { headers })).status, 400);
  const data = await fetch(base + '/api/crashes?days=30', { headers });
  assert.deepEqual(await data.json(), { days: 30, issues: [] });
});

test('PDF route denies invalid identity, foreign owner, non-PDF and oversized uploads', async (context) => {
  let cloudCalls = 0;
  const server = createMediaServer({
    verifyToken: async (token) => {
      if (token !== 'owner-token') throw new Error('invalid token');
      return { uid: 'student-a' };
    },
    upload: async (bytes, id) => {
      cloudCalls++;
      assert.equal(bytes.toString('ascii'), '%PDF-test');
      return { public_id: id, type: 'authenticated' };
    },
    download: async (id) => {
      cloudCalls++;
      assert.equal(id, 'reports/student-a/study_report_1793802523924.pdf');
      return new Response('%PDF-test');
    },
  });
  const base = await start(server, context);
  const path = '/api/reports/student-a/study_report_1793802523924.pdf';
  const auth = { authorization: 'Bearer owner-token' };
  assert.equal((await fetch(base + path)).status, 401);
  assert.equal((await fetch(base + path.replace('student-a', 'student-b'), { headers: auth })).status, 403);
  const headers = { ...auth, 'content-type': 'application/pdf' };
  assert.equal((await fetch(base + path, { method: 'PUT', headers, body: 'not PDF' })).status, 415);
  assert.equal((await fetch(base + path, {
    method: 'PUT', headers, body: Buffer.alloc(10 * 1024 * 1024 + 1),
  })).status, 413);
  assert.equal(cloudCalls, 0);

  const upload = await fetch(base + path, { method: 'PUT', headers, body: '%PDF-test' });
  assert.equal(upload.status, 201);
  assert.deepEqual(await upload.json(), { storagePath: path.slice(5) });
  const download = await fetch(base + path, { headers: auth });
  assert.equal(download.status, 200);
  assert.equal(download.headers.get('content-type'), 'application/pdf');
  assert.equal(await download.text(), '%PDF-test');
  assert.equal(cloudCalls, 2);
});
