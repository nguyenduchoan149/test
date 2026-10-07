const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = Number(process.env.PORT) || 3456;
const ROOT = __dirname;
const PUBLIC_DIR = path.join(ROOT, 'public');
const BIN_DIR = path.join(ROOT, 'bin');
const MAIN_EXE = path.join(
  BIN_DIR,
  process.platform === 'win32' ? 'MAIN.exe' : 'MAIN'
);

function sendJson(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(payload),
  });
  res.end(payload);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

function runCobol(raw) {
  return new Promise((resolve, reject) => {
    if (!fs.existsSync(MAIN_EXE)) {
      reject(
        new Error(
          `MAIN not found: ${MAIN_EXE}. Run .\\scripts\\build-local.ps1 first.`
        )
      );
      return;
    }

    const input = `${raw}\n`;
    const child = spawn(MAIN_EXE, [], {
      cwd: BIN_DIR,
      env: { ...process.env, COB_LIBRARY_PATH: BIN_DIR },
      stdio: ['pipe', 'pipe', 'pipe'],
      windowsHide: true,
    });

    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (d) => {
      stdout += d.toString('utf8');
    });
    child.stderr.on('data', (d) => {
      stderr += d.toString('utf8');
    });
    child.on('error', reject);
    child.on('close', (code) => resolve({ code, stdout, stderr }));

    child.stdin.write(input);
    child.stdin.end();
  });
}

function serveStatic(req, res) {
  let urlPath = decodeURIComponent(
    new URL(req.url, `http://${req.headers.host}`).pathname
  );
  if (urlPath === '/') urlPath = '/calculator.html';

  const filePath = path.normalize(path.join(PUBLIC_DIR, urlPath));
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    res.writeHead(404);
    res.end('Not found');
    return;
  }

  const ext = path.extname(filePath).toLowerCase();
  const types = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
  };
  res.writeHead(200, { 'Content-Type': types[ext] || 'application/octet-stream' });
  fs.createReadStream(filePath).pipe(res);
}

async function handleCalculate(req, res) {
  try {
    let body;
    try {
      body = JSON.parse((await readBody(req)) || '{}');
    } catch {
      body = {};
    }

    const raw = body.raw != null ? String(body.raw) : '';
    const { code, stdout, stderr } = await runCobol(raw);

    // Log toan bo stdout COBOL (LOGIC01..05 + MAIN)
    String(stdout || '')
      .split(/\r?\n/)
      .map((l) => l.trimEnd())
      .filter((l) => l.length > 0)
      .forEach((l) => console.log(l));

    if (stderr && stderr.trim()) {
      console.error(stderr.trim());
    }
    if (code) {
      console.log('exit', code);
    }

    sendJson(res, 200, { ok: true });
  } catch (err) {
    console.error(err);
    sendJson(res, 500, { ok: false });
  }
}

const server = http.createServer(async (req, res) => {
  const { pathname } = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === 'POST' && pathname === '/api/calculate') {
    await handleCalculate(req, res);
    return;
  }
  if (req.method === 'GET') {
    serveStatic(req, res);
    return;
  }
  res.writeHead(405);
  res.end('Method Not Allowed');
});

server.listen(PORT, () => {
  console.log(`http://localhost:${PORT}/calculator.html`);
});
