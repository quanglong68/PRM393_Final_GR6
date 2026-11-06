import { createServer } from 'node:http';
import { pathToFileURL } from 'node:url';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { v2 as cloudinary } from 'cloudinary';
import { projectId } from './firebase-api.mjs';
import { createGeminiAdvisor, validateAdvisorInput } from './advisor.mjs';

const maxBytes = 10 * 1024 * 1024;
const noteTypes = {
  md: 'text/markdown',
  markdown: 'text/markdown',
  pdf: 'application/pdf',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  txt: 'text/plain',
  png: 'image/png',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
};
const noteRoute = /^\/api\/notes\/([A-Za-z0-9_-]{1,128})\/cloudinary\/(note_\d{16}\.([a-z]+))$/;
const reportRoute = /^\/api\/reports\/([A-Za-z0-9_-]{1,128})\/(study_report_\d{13}\.pdf)$/;
const advisorRoute = /^\/api\/advisor\/([A-Za-z0-9_-]{1,128})$/;

function uploadAsset(bytes, id) {
  return new Promise((resolve, reject) => {
    cloudinary.uploader.upload_stream({
      public_id: id, resource_type: 'raw', type: 'authenticated',
      overwrite: false, timeout: 30000,
    }, (error, asset) => error ? reject(error) : resolve(asset)).end(bytes);
  });
}

async function readFile(req, maxSize, contentType) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req.iterator({ destroyOnReturn: false })) {
    size += chunk.length;
    if (size > maxSize) return { status: 413, error: 'Tệp vượt giới hạn kích thước.' };
    chunks.push(chunk);
  }
  const bytes = Buffer.concat(chunks);
  if (bytes.length === 0) return { status: 415, error: 'Tệp rỗng.' };
  if (contentType === 'application/pdf' && bytes.subarray(0, 5).toString('ascii') !== '%PDF-') {
    return { status: 415, error: 'Dữ liệu phải là PDF.' };
  }
  if (contentType === noteTypes.docx && !bytes.subarray(0, 4).equals(Buffer.from([0x50, 0x4b, 0x03, 0x04]))) {
    return { status: 415, error: 'Dữ liệu phải là tệp DOCX.' };
  }
  return { bytes };
}

async function downloadAsset(id) {
  const url = cloudinary.utils.private_download_url(id, '', {
    resource_type: 'raw', type: 'authenticated',
    expires_at: Math.floor(Date.now() / 1000) + 60,
  });
  return fetch(url, { signal: AbortSignal.timeout(30000), redirect: 'error' });
}

export function createMediaServer({
  verifyToken, upload = uploadAsset, download = downloadAsset, advisor,
  remove = (id) => cloudinary.uploader.destroy(id, {
    resource_type: 'raw', type: 'authenticated', invalidate: true,
  }),
}) {
  const server = createServer(async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    const reply = (status, data) => {
      res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(data));
    };
    if (!/^(127\.0\.0\.1|localhost)(:\d+)?$/i.test(req.headers.host ?? '')) {
      return reply(400, { error: 'Host không hợp lệ.' });
    }
    const report = reportRoute.exec(req.url ?? '');
    const note = noteRoute.exec(req.url ?? '');
    const ask = advisorRoute.exec(req.url ?? '');
    const route = report ?? note ?? ask;
    if (!route) return reply(404, { error: 'Không tìm thấy tệp.' });

    const bearer = /^Bearer (\S+)$/.exec(req.headers.authorization ?? '');
    let uid;
    if (bearer) {
      try { uid = (await verifyToken(bearer[1])).uid; } catch { /* Invalid token. */ }
    }
    if (!uid) return reply(401, { error: 'Cần đăng nhập trong app.' });
    if (uid !== route[1]) return reply(403, { error: 'Tệp thuộc tài khoản khác.' });

    if (ask) {
      if (req.method !== 'POST') return reply(405, { error: 'Chỉ hỗ trợ POST.' });
      if (!advisor) return reply(503, { error: 'Chưa cấu hình Gemini trên máy chủ.' });
      if (req.headers['content-type']?.split(';')[0] !== 'application/json') {
        return reply(415, { error: 'Yêu cầu phải dùng JSON.' });
      }
      try {
        const input = await readFile(req, 24 * 1024, 'application/json');
        if (input.error) return reply(input.status, { error: input.error });
        let data;
        try { data = JSON.parse(input.bytes.toString('utf8')); }
        catch { return reply(400, { error: 'JSON không hợp lệ.' }); }
        if (!validateAdvisorInput(data)) {
          return reply(400, { error: 'Dữ liệu hỏi đáp không hợp lệ.' });
        }
        const { question, level, catalog } = data;
        const { status, answer } = await advisor({ question, level, catalog });
        return reply(status, status === 200 ? { answer } : {
          error: status === 429 ? 'Gemini đang giới hạn lượt hỏi.' : 'Gemini chưa trả lời được.',
        });
      } catch {
        return reply(502, { error: 'Gemini chưa trả lời được.' });
      }
    }

    const contentType = report ? 'application/pdf' : noteTypes[note[3]];
    if (!contentType) return reply(415, { error: 'Định dạng tệp không được hỗ trợ.' });
    const fileName = route[2];
    const id = report ? `reports/${uid}/${fileName}` : `notes/${uid}/cloudinary/${fileName}`;
    const maxSize = report ? maxBytes : maxBytes - 1;
    try {
      if (req.method === 'PUT') {
        if (req.headers['content-type'] !== contentType) {
          return reply(415, { error: 'Định dạng tệp không khớp.' });
        }
        if (Number(req.headers['content-length']) > maxSize) {
          return reply(413, { error: 'Tệp vượt giới hạn kích thước.' });
        }
        const file = await readFile(req, maxSize, contentType);
        if (file.error) return reply(file.status, { error: file.error });
        const asset = await upload(file.bytes, id);
        if (asset?.public_id !== id || asset?.type !== 'authenticated') {
          return reply(502, { error: 'Dịch vụ lưu trữ chưa xác nhận tệp.' });
        }
        return reply(201, { storagePath: id });
      }
      if (req.method === 'GET') {
        const file = await download(id);
        if (file.status === 404) return reply(404, { error: 'Tệp chưa tồn tại.' });
        if (!file.ok || !file.body) return reply(502, { error: 'Không tải được tệp.' });
        res.writeHead(200, {
          'Content-Type': contentType,
          'Content-Disposition': `attachment; filename="${fileName}"`,
        });
        return await pipeline(Readable.fromWeb(file.body), res);
      }
      if (req.method === 'DELETE') {
        const result = await remove(id);
        if (result?.result !== 'ok' && result?.result !== 'not found') {
          return reply(502, { error: 'Không xóa được tệp.' });
        }
        res.writeHead(204).end();
        return;
      }
      return reply(405, { error: 'Phương thức không hỗ trợ.' });
    } catch {
      if (res.headersSent) res.destroy();
      else reply(502, { error: 'Cloudinary không xử lý được tệp. Hãy thử lại.' });
    }
  });
  server.requestTimeout = 45000;
  server.headersTimeout = 15000;
  return server;
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  const { CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET } = process.env;
  if (!CLOUDINARY_CLOUD_NAME || !CLOUDINARY_API_KEY || !CLOUDINARY_API_SECRET) {
    throw new Error('Set Cloudinary server credentials in .env.');
  }
  cloudinary.config({
    cloud_name: CLOUDINARY_CLOUD_NAME, api_key: CLOUDINARY_API_KEY,
    api_secret: CLOUDINARY_API_SECRET, secure: true,
  });
  const app = initializeApp({ projectId: projectId() });
  const port = Number(process.env.MEDIA_PORT || 8788);
  createMediaServer({
    verifyToken: (token) => getAuth(app).verifyIdToken(token),
    advisor: createGeminiAdvisor(process.env.GEMINI_API_KEY, process.env.GEMINI_MODEL),
  })
    .listen(port, '127.0.0.1', () => console.log(`Media API: http://127.0.0.1:${port}`));
}
