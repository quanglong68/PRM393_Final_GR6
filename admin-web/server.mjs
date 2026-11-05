import { timingSafeEqual } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { pathToFileURL } from 'node:url';
import { FirebaseApiError, getCrashReport } from './firebase-api.mjs';

const assets = {
  '/': ['text/html; charset=utf-8', 'index.html'],
  '/style.css': ['text/css; charset=utf-8', 'style.css'],
  '/dashboard.js': ['text/javascript; charset=utf-8', 'dashboard.js'],
};

export function createAdminServer({ password, readReport = getCrashReport }) {
  if (typeof password !== 'string' || password.length < 24) {
    throw new Error('Set ADMIN_PASSWORD to at least 24 characters.');
  }
  const expected = Buffer.from(`admin:${password}`, 'utf8');
  return createServer(async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Content-Security-Policy', "default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'");
    const reply = (status, data) => {
      res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(data));
    };

    if (!/^(127\.0\.0\.1|localhost)(:\d+)?$/i.test(req.headers.host ?? '')) {
      return reply(400, { error: 'Chỉ phục vụ trên máy admin.' });
    }
    const authHeader = req.headers.authorization ?? '';
    const supplied = Buffer.from(authHeader.startsWith('Basic ') ? authHeader.slice(6) : '', 'base64');
    if (supplied.length !== expected.length || !timingSafeEqual(supplied, expected)) {
      res.setHeader('WWW-Authenticate', 'Basic realm="Lab 3 Admin", charset="UTF-8"');
      return reply(401, { error: 'Cần tài khoản admin.' });
    }
    if (req.method !== 'GET') return reply(405, { error: 'Dashboard chỉ đọc.' });

    const url = new URL(req.url, 'http://127.0.0.1');
    if (url.pathname === '/api/crashes') {
      const days = url.searchParams.get('days') ?? '7';
      if (!['1', '7', '30'].includes(days)) {
        return reply(400, { error: 'Chọn khoảng 1, 7 hoặc 30 ngày.' });
      }
      try {
        return reply(200, await readReport(Number(days)));
      } catch (error) {
        if (error instanceof FirebaseApiError && [401, 403].includes(error.status)) {
          return reply(502, { error: 'Server chưa có quyền đọc Crashlytics. Kiểm tra tài khoản Google Cloud.' });
        }
        return reply(502, { error: 'Không tải được báo cáo Crashlytics. Kiểm tra cấu hình và thử lại.' });
      }
    }
    const asset = Object.hasOwn(assets, url.pathname) ? assets[url.pathname] : null;
    if (!asset) return reply(404, { error: 'Không tìm thấy trang.' });
    res.writeHead(200, { 'Content-Type': asset[0] });
    res.end(readFileSync(new URL(asset[1], import.meta.url)));
  });
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  const port = Number(process.env.ADMIN_PORT || 8787);
  createAdminServer({ password: process.env.ADMIN_PASSWORD })
    .listen(port, '127.0.0.1', () => console.log(`Admin web: http://127.0.0.1:${port}`));
}
