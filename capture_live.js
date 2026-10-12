const http = require('http');
const fs = require('fs');
const { spawn } = require('child_process');

const edgePath = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const port = 9222;

async function run() {
  console.log('Starting Edge with debugging...');
  const edgeProc = spawn(edgePath, [
    `--remote-debugging-port=${port}`,
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--no-first-run',
    '--no-default-browser-check',
    '--window-size=1400,2600',
    'http://127.0.0.1:3838'
  ], { detached: false });

  let pageTarget = null;
  for (let i = 0; i < 30; i++) {
    await new Promise(r => setTimeout(r, 600));
    try {
      const targets = await new Promise((resolve, reject) => {
        http.get(`http://127.0.0.1:${port}/json/list`, res => {
          let body = '';
          res.on('data', chunk => body += chunk);
          res.on('end', () => resolve(JSON.parse(body)));
        }).on('error', reject);
      });
      pageTarget = targets.find(t => t.type === 'page' && t.url.includes('3838'));
      if (pageTarget && pageTarget.webSocketDebuggerUrl) break;
    } catch (e) {}
  }

  if (!pageTarget) {
    console.error('Page target not found');
    edgeProc.kill();
    return;
  }

  console.log('Connected to Page WebSocket:', pageTarget.webSocketDebuggerUrl);
  const ws = new globalThis.WebSocket(pageTarget.webSocketDebuggerUrl);

  let id = 1;
  const pending = new Map();

  ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg);
      pending.delete(msg.id);
    }
  };

  await new Promise(resolve => ws.onopen = resolve);

  function send(method, params = {}) {
    return new Promise((resolve) => {
      const reqId = id++;
      pending.set(reqId, resolve);
      ws.send(JSON.stringify({ id: reqId, method, params }));
    });
  }

  await send('Page.enable');
  await send('Runtime.enable');

  console.log('Waiting 6 seconds for complete Shiny WebSocket rendering...');
  await new Promise(r => setTimeout(r, 6000));

  // 1. Desktop Screenshot
  console.log('Capturing Desktop Screenshot...');
  await send('Emulation.setDeviceMetricsOverride', {
    width: 1400,
    height: 2600,
    deviceScaleFactor: 1,
    mobile: false
  });
  await new Promise(r => setTimeout(r, 1000));
  const snap1 = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true });
  fs.writeFileSync('screenshots/desktop_1400.png', Buffer.from(snap1.result.data, 'base64'));

  // 2. Mobile Screenshot
  console.log('Capturing Mobile Screenshot...');
  await send('Emulation.setDeviceMetricsOverride', {
    width: 390,
    height: 3400,
    deviceScaleFactor: 2,
    mobile: true
  });
  await new Promise(r => setTimeout(r, 1200));
  const snap2 = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true });
  fs.writeFileSync('screenshots/mobile_390.png', Buffer.from(snap2.result.data, 'base64'));

  console.log('All screenshots saved successfully!');
  ws.close();
  edgeProc.kill();
  process.exit(0);
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});
