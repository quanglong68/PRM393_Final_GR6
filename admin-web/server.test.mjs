import assert from 'node:assert/strict';
import { once } from 'node:events';
import test from 'node:test';
import { createAdminServer } from './server.mjs';
import { createMediaServer } from './media-server.mjs';
import { createGeminiAdvisor } from './advisor.mjs';

async function start(server, context) {
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  context.after(() => new Promise((resolve) => server.close(resolve)));
  return `http://127.0.0.1:${server.address().port}`;
}

test('advisor sends only validated academic fields to Gemini for the signed-in owner', async (context) => {
  let calls = 0;
  const advisor = createGeminiAdvisor('test-only-key', 'gemini-test', async (url, options) => {
    calls++;
    assert.equal(new URL(url).hostname, 'generativelanguage.googleapis.com');
    assert.equal(options.headers['x-goog-api-key'], 'test-only-key');
    const data = JSON.parse(options.body);
    assert.deepEqual(JSON.parse(data.contents[0].parts[0].text), {
      question: 'PRM323 có bao nhiêu tín chỉ?', level: 'course', catalog: 'PRM323: 3 tín chỉ',
    });
    return Response.json({ candidates: [{ content: { parts: [{ text: 'PRM323 có 3 tín chỉ.' }] } }] });
  });
  const base = await start(createMediaServer({
    advisor,
    verifyToken: async (token) => {
      if (token !== 'owner-token') throw Error('invalid token');
      return { uid: 'student-a' };
    },
  }), context);
  const path = base + '/api/advisor/student-a';
  const options = {
    method: 'POST',
    headers: { authorization: 'Bearer owner-token', 'content-type': 'application/json' },
    body: JSON.stringify({
      question: 'PRM323 có bao nhiêu tín chỉ?', level: 'course',
      catalog: 'PRM323: 3 tín chỉ', privateTranscript: ['do not forward'],
    }),
  };
  assert.equal((await fetch(path, { ...options, headers: { 'content-type': 'application/json' } })).status, 401);
  assert.equal((await fetch(path.replace('student-a', 'student-b'), options)).status, 403);
  assert.equal((await fetch(path, { ...options, body: '{}' })).status, 400);
  assert.equal(calls, 0);
  const response = await fetch(path, options);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { answer: 'PRM323 có 3 tín chỉ.' });
  assert.equal(calls, 1);
});

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

test('private note attachments round trip through the same media API', async (context) => {
  const assets = new Map();
  const server = createMediaServer({
    verifyToken: async (token) => {
      if (token === 'owner-token') return { uid: 'student-a' };
      if (token === 'other-token') return { uid: 'student-b' };
      throw new Error('invalid token');
    },
    upload: async (bytes, id) => {
      assets.set(id, bytes);
      return { public_id: id, type: 'authenticated' };
    },
    download: async (id) => assets.has(id)
      ? new Response(assets.get(id))
      : new Response(null, { status: 404 }),
  });
  const base = await start(server, context);
  const samples = [
    ['md', 'text/markdown', Buffer.from('# Lab 3')],
    ['pdf', 'application/pdf', Buffer.from('%PDF-test')],
    ['docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      Buffer.from([0x50, 0x4b, 0x03, 0x04])],
  ];
  const auth = { authorization: 'Bearer owner-token' };
  const other = { authorization: 'Bearer other-token' };
  for (const [extension, contentType, bytes] of samples) {
    const path = `/api/notes/student-a/cloudinary/note_1793802523924123.${extension}`;
    assert.equal((await fetch(base + path, { headers: auth })).status, 404);
    const upload = await fetch(base + path, {
      method: 'PUT', headers: { ...auth, 'content-type': contentType }, body: bytes,
    });
    assert.equal(upload.status, 201);
    assert.deepEqual(await upload.json(), { storagePath: path.slice(5) });
    assert.equal((await fetch(base + path)).status, 401);
    assert.equal((await fetch(base + path, { headers: other })).status, 403);
    const result = await fetch(base + path, { headers: auth });
    assert.equal(result.status, 200);
    assert.equal(result.headers.get('content-type'), contentType);
    assert.deepEqual(Buffer.from(await result.arrayBuffer()), bytes);
  }
  const basePath = base + '/api/notes/student-a/cloudinary/note_1793802523924124';
  const markdown = { ...auth, 'content-type': 'text/markdown' };
  assert.equal((await fetch(basePath + '.exe', {
    method: 'PUT', headers: markdown, body: 'exe',
  })).status, 415);
  assert.equal((await fetch(basePath + '.docx', {
    method: 'PUT', headers: markdown, body: '# incorrect type',
  })).status, 415);
  assert.equal((await fetch(basePath + '.md', {
    method: 'PUT', headers: markdown, body: Buffer.alloc(10 * 1024 * 1024),
  })).status, 413);
  assert.equal(assets.size, 3);
});
