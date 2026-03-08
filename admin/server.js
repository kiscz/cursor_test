#!/usr/bin/env node
/**
 * 简单静态服务，用于 Railway 部署
 * 监听 PORT，支持 SPA 路由回退到 index.html
 */
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;
const ROOT = path.join(__dirname, 'dist');

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

// 运行时 API 地址：Railway 设置 API_BASE_URL 或 VITE_API_BASE_URL
const API_BASE = process.env.API_BASE_URL || process.env.VITE_API_BASE_URL || '/api';

const server = http.createServer((req, res) => {
  const urlPath = (req.url || '/').split('?')[0];

  // 动态返回 config.json，使用环境变量中的 API 地址
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
