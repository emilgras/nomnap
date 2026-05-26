#!/usr/bin/env node
// Wraps `flutter run -d chrome` so its stdin can be driven over HTTP.
// Once running, trigger Flutter's interactive commands without restarting:
//   curl http://localhost:9999/r   hot reload
//   curl http://localhost:9999/R   hot restart
//   curl http://localhost:9999/q   quit
//   curl http://localhost:9999/status

const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = parseInt(process.env.RELOAD_PORT || '9999', 10);
const WEB_PORT = parseInt(process.env.WEB_PORT || '8765', 10);
const LOG_PATH = path.join(__dirname, '..', '.dev-server.log');

const logStream = fs.createWriteStream(LOG_PATH, { flags: 'a' });
const log = (msg) => {
  const line = `[${new Date().toISOString()}] ${msg}\n`;
  process.stdout.write(line);
  logStream.write(line);
};

const isWin = process.platform === 'win32';
const flutter = spawn(
  isWin ? 'flutter.bat' : 'flutter',
  ['run', '-d', 'chrome', '--web-port', String(WEB_PORT)],
  // shell: true is required on Windows so PATH lookup finds flutter.bat;
  // without it Node spawn throws EINVAL for .bat files (Node 16+ security).
  { stdio: ['pipe', 'pipe', 'pipe'], shell: isWin },
);

let ready = false;
const pipeLines = (stream, prefix) => {
  let buf = '';
  stream.on('data', (chunk) => {
    buf += chunk.toString();
    let i;
    while ((i = buf.indexOf('\n')) >= 0) {
      const line = buf.slice(0, i);
      buf = buf.slice(i + 1);
      log(`${prefix} ${line}`);
      if (!ready && /Flutter run key commands|is being served at/.test(line)) {
        ready = true;
        log(`>> READY. HTTP control: http://localhost:${PORT}/r (reload), /R (restart), /q (quit)`);
      }
    }
  });
};
pipeLines(flutter.stdout, 'flutter>');
pipeLines(flutter.stderr, 'flutter!');

flutter.on('exit', (code) => {
  log(`flutter exited code=${code}`);
  process.exit(code ?? 0);
});

const send = (ch) => {
  if (!flutter.stdin.writable) return false;
  flutter.stdin.write(ch);
  log(`<< sent ${JSON.stringify(ch)}`);
  return true;
};

http.createServer((req, res) => {
  const url = req.url || '/';
  res.setHeader('Content-Type', 'text/plain');
  if (url === '/status') {
    res.end(JSON.stringify({
      pid: flutter.pid,
      ready,
      webPort: WEB_PORT,
    }));
    return;
  }
  const cmd = url.replace(/^\/+/, '');
  if (['r', 'R', 'q', 'h', 'd', 'c'].includes(cmd)) {
    if (!ready) {
      res.statusCode = 503;
      res.end('flutter not ready yet');
      return;
    }
    if (send(cmd)) {
      res.end(`ok: sent ${cmd}\n`);
    } else {
      res.statusCode = 500;
      res.end('flutter stdin not writable');
    }
    return;
  }
  res.statusCode = 404;
  res.end(`Unknown: ${url}\nValid: /r /R /q /h /d /c /status\n`);
}).listen(PORT, '127.0.0.1', () => {
  log(`HTTP control listening on http://localhost:${PORT}`);
});

const cleanup = () => {
  if (flutter.stdin.writable) flutter.stdin.write('q');
  setTimeout(() => process.exit(0), 1000);
};
process.on('SIGINT', cleanup);
process.on('SIGTERM', cleanup);
