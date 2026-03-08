#!/usr/bin/env node
/**
 * 简单静态服务，用于 Railway 部署
 * 监听 PORT，支持 SPA 路由回退到 index.html
 * 当 BACKEND_URL 存在时，/api 请求代理到后端，避免 CORS
 */
const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const PORT = process.env.PORT || 8080;
const ROOT = path.join(__dirname, 'dist');

// 后端地址：设置后 /api 代理到此后端，前端用 /api（同源，无 CORS）
function normalizeBackendUrl(s) {
  const u = (s || '').trim().replace(/\/api\/?$/, '');
  if (!u) return '';
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  return 'https://' + u;
}
const BACKEND_URL = normalizeBackendUrl(process.env.BACKEND_URL || process.env.API_BASE_URL || process.env.VITE_API_BASE_URL);

const MIME = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

// 前端 API 地址：有代理时用 /api（同源），否则用完整 URL
const API_BASE = BACKEND_URL ? '/api' : (process.env.API_BASE_URL || process.env.VITE_API_BASE_URL || '/api');

function proxyToBackend(req, res, urlPath, query) {
  const targetUrl = BACKEND_URL + urlPath + (query ? '?' + query : '');
  const u = new URL(targetUrl);
  const client = u.protocol === 'https:' ? https : http;
  const opts = {
    hostname: u.hostname,
    port: u.port || (u.protocol === 'https:' ? 443 : 80),
    path: u.pathname + u.search,
    method: req.method,
    headers: { ...req.headers, host: u.host }
  };
  const proxyReq = client.request(opts, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });
  proxyReq.on('error', (err) => {
    console.error('Proxy error:', err.message);
    res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Backend unreachable', message: err.message }));
  });
  req.pipe(proxyReq);
}

const server = http.createServer((req, res) => {
  const [urlPath, query] = (req.url || '/').split('?');
  const qs = query ? '?' + query : '';

  // /api 代理到后端（避免 CORS）
  if (BACKEND_URL && urlPath.startsWith('/api')) {
    proxyToBackend(req, res, urlPath, query);
    return;
  }

  // 动态返回 config.json
  if (urlPath === '/config.json') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ apiBaseUrl: API_BASE }));
    return;
  }

  let filePath = path.join(ROOT, urlPath === '/' ? 'index.html' : urlPath);

  fs.stat(filePath, (statErr, stat) => {
    if (statErr || !stat.isFile()) {
      filePath = path.join(ROOT, 'index.html');
    } else if (stat.isDirectory()) {
      filePath = path.join(filePath, 'index.html');
    }

    fs.readFile(filePath, (err, data) => {
      if (err) {
        fs.readFile(path.join(ROOT, 'index.html'), (e, d) => {
          res.writeHead(e ? 404 : 200, { 'Content-Type': 'text/html' });
          res.end(e ? 'Not Found' : d);
        });
        return;
      }
      const ext = path.extname(filePath);
      res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
      res.end(data);
    });
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});
