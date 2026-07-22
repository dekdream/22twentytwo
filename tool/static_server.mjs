import { createServer } from 'node:http';
import { createReadStream, statSync } from 'node:fs';
import { extname, join, resolve, normalize } from 'node:path';

const root = resolve(process.argv[2] ?? 'build/web');
const port = Number(process.argv[3] ?? 5173);

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
};

createServer((request, response) => {
  const url = new URL(request.url ?? '/', `http://${request.headers.host}`);
  const cleanPath = normalize(decodeURIComponent(url.pathname)).replace(/^(\.\.[/\\])+/, '');
  let filePath = resolve(join(root, cleanPath));

  if (!filePath.startsWith(root)) {
    response.writeHead(403);
    response.end('Forbidden');
    return;
  }

  try {
    const stats = statSync(filePath);
    if (stats.isDirectory()) filePath = join(filePath, 'index.html');
  } catch {
    filePath = join(root, 'index.html');
  }

  response.writeHead(200, {
    'content-type': types[extname(filePath)] ?? 'application/octet-stream',
    'cache-control': 'no-store',
  });
  createReadStream(filePath).pipe(response);
}).listen(port, '127.0.0.1', () => {
  console.log(`Serving ${root} at http://127.0.0.1:${port}`);
});
