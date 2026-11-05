import { createServer } from 'node:http';
import { pathToFileURL } from 'node:url';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { v2 as cloudinary } from 'cloudinary';
import { projectId } from './firebase-api.mjs';

const maxBytes = 10 * 1024 * 1024;
const reportRoute = /^\/api\/reports\/([A-Za-z0-9_-]{1,128})\/(study_report_\d{13}\.pdf)$/;

function uploadPdf(bytes, id) {
  return new Promise((resolve, reject) => {
    cloudinary.uploader.upload_stream({
      public_id: id, resource_type: 'raw', type: 'authenticated',
      overwrite: false, timeout: 30000,
    }, (error, asset) => error ? reject(error) : resolve(asset)).end(bytes);
  });
}

async function readPdf(req) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req.iterator({ destroyOnReturn: false })) {
    size += chunk.length;
    if (size > maxBytes) return { status: 413, error: 'PDF tối đa 10 MB.' };
    chunks.push(chunk);
  }
  const bytes = Buffer.concat(chunks);
  if (bytes.subarray(0, 5).toString('ascii') !== '%PDF-') {
    return { status: 415, error: 'Dữ liệu phải là PDF.' };
  }
  return { bytes };
}

async function downloadPdf(id) {
  const url = cloudinary.utils.private_download_url(id, '', {
    resource_type: 'raw', type: 'authenticated',
    expires_at: Math.floor(Date.now() / 1000) + 60,
  });
  return fetch(url, { signal: AbortSignal.timeout(30000), redirect: 'error' });
}

export function createMediaServer({
  verifyToken, upload = uploadPdf, download = downloadPdf,
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
    const path = new URL(req.url, 'http://127.0.0.1').pathname;
    const route = reportRoute.exec(path);
    if (!route) return reply(404, { error: 'Không tìm thấy báo cáo.' });

    const bearer = /^Bearer (\S+)$/.exec(req.headers.authorization ?? '');
    let uid;
    if (bearer) {
      try { uid = (await verifyToken(bearer[1])).uid; } catch { /* Invalid token. */ }
    }
    if (!uid) return reply(401, { error: 'Cần đăng nhập trong app.' });
    if (uid !== route[1]) return reply(403, { error: 'Báo cáo thuộc tài khoản khác.' });

    const id = `reports/${uid}/${route[2]}`;
    try {
      if (req.method === 'PUT') {
        if (req.headers['content-type'] !== 'application/pdf') {
          return reply(415, { error: 'Dữ liệu phải là PDF.' });
        }
        if (Number(req.headers['content-length']) > maxBytes) {
          return reply(413, { error: 'PDF tối đa 10 MB.' });
        }
        const pdf = await readPdf(req);
        if (pdf.error) return reply(pdf.status, { error: pdf.error });
        const asset = await upload(pdf.bytes, id);
        if (asset?.public_id !== id || asset?.type !== 'authenticated') {
          return reply(502, { error: 'Dịch vụ lưu trữ chưa xác nhận báo cáo.' });
        }
        return reply(201, { storagePath: id });
      }
      if (req.method === 'GET') {
        const pdf = await download(id);
        if (pdf.status === 404) return reply(404, { error: 'Báo cáo chưa tồn tại.' });
        if (!pdf.ok || !pdf.body) return reply(502, { error: 'Không tải được PDF.' });
        res.writeHead(200, {
          'Content-Type': 'application/pdf',
          'Content-Disposition': `attachment; filename="${route[2]}"`,
        });
        return await pipeline(Readable.fromWeb(pdf.body), res);
      }
      if (req.method === 'DELETE') {
        const result = await remove(id);
        if (result?.result !== 'ok' && result?.result !== 'not found') {
          return reply(502, { error: 'Không xóa được báo cáo.' });
        }
        res.writeHead(204).end();
        return;
      }
      return reply(405, { error: 'Phương thức không hỗ trợ.' });
    } catch {
      if (res.headersSent) res.destroy();
      else reply(502, { error: 'Cloudinary không xử lý được báo cáo. Hãy thử lại.' });
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
  createMediaServer({ verifyToken: (token) => getAuth(app).verifyIdToken(token) })
    .listen(port, '127.0.0.1', () => console.log(`Media API: http://127.0.0.1:${port}`));
}
