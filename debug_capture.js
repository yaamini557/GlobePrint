const http = require('http');
const fs = require('fs');
const { spawn } = require('child_process');

const edgePath = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const port = 9222;

async function run() {
  const edgeProc = spawn(edgePath, [
    `--remote-debugging-port=${port}`,
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--no-first-run',
    '--no-default-browser-check',
    '--window-size=1400,2600',
    'http://127.0.0.1:3838'
  ]);

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

  const ws = new globalThis.WebSocket(pageTarget.webSocketDebuggerUrl);

  let id = 1;
  const pending = new Map();

  ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    if (msg.method === 'Runtime.consoleAPICalled') {
      console.log('BROWSER CONSOLE:', msg.params.type, msg.params.args);
    }
    if (msg.method === 'Runtime.exceptionThrown') {
      console.log('BROWSER EXCEPTION:', msg.params);
    }
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
  await send('Log.enable');

  // Check Shiny shiny:connected or Shiny.shinyapp.isConnected()
  for (let i = 0; i < 20; i++) {
    await new Promise(r => setTimeout(r, 500));
    const res = await send('Runtime.evaluate', {
      expression: 'window.Shiny && window.Shiny.shinyapp && window.Shiny.shinyapp.isConnected()'
    });
    console.log(`Check ${i}: Shiny connected?`, res?.result?.result?.value);
    if (res?.result?.result?.value === true) break;
  }

  // Check DOM elements
  const evalDom = await send('Runtime.evaluate', {
    expression: '({ kpi: document.querySelectorAll(".kpi-card").length, images: document.querySelectorAll(".poster-frame img").length, leaflet: document.querySelectorAll(".leaflet-container").length })',
    returnByValue: true
  });
  console.log('DOM Evaluation:', evalDom?.result?.result?.value);

  await new Promise(r => setTimeout(r, 2000));

  const snap1 = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true });
  fs.writeFileSync('screenshots/desktop_1400.png', Buffer.from(snap1.result.data, 'base64'));

  ws.close();
  edgeProc.kill();
  process.exit(0);
}

run().catch(console.error);
