const express = require('express');
const axios = require('axios');
const os = require('os');

const app = express();
const PORT = 3000;

app.get('/', async (req, res) => {
 try {
  //fetch metrics from backend
  const backendUrl = process.env.BACKEND_URL || 'http://app-server:5000/metrics';
  const response = await axios.get(backendUrl);
  const metrics = response.data;

  res.send(`
      <html>
        <head>
          <title>Infrastructure Metrics</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body { font-family: Arial, sans-serif; background: #f4f4f4; margin: 0; padding: 2em; }
            .container { background: #fff; border-radius: 8px; padding: 2em; max-width: 600px; margin: auto; box-shadow: 0 2px 8px #ccc; }
            h1 { color: #333; text-align: center; }
            .metrics { display: flex; flex-wrap: wrap; justify-content: space-between; }
            .metric {
              flex: 1 1 45%;
              background: #e3f2fd;
              margin: 1em 0.5em;
              padding: 1em;
              border-radius: 6px;
              box-shadow: 0 1px 4px #bbb;
              text-align: center;
              transition: transform 0.3s, box-shadow 0.3s;
              animation: fadeIn 1s;
            }
            .metric:hover {
              transform: scale(1.05);
              box-shadow: 0 4px 16px #90caf9;
            }
            @media (max-width: 600px) {
              .metrics { flex-direction: column; }
              .metric { flex: 1 1 100%; margin: 1em 0; }
            }
            @keyframes fadeIn {
              from { opacity: 0; transform: translateY(20px);}
              to { opacity: 1; transform: translateY(0);}
            }
            .raw { background: #f9fbe7; padding: 1em; border-radius: 4px; margin-top: 2em; font-size: 0.9em; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>Infrastructure Metrics</h1>
            <div class="metrics">
              <div class="metric"><strong>Frontend Hostname</strong><br>${os.hostname()}</div>
              <div class="metric"><strong>Backend Hostname</strong><br>${metrics.hostname}</div>
              <div class="metric"><strong>OS</strong><br>${metrics.os} (${metrics.platform})</div>
              <div class="metric"><strong>CPU</strong><br>${metrics.cpu} (${metrics.cores} cores)</div>
              <div class="metric"><strong>Memory</strong><br>${(metrics.totalmem/1024/1024).toFixed(0)} MB total<br>${(metrics.freemem/1024/1024).toFixed(0)} MB free</div>
              <div class="metric"><strong>Uptime</strong><br>${Math.floor(metrics.uptime/3600)}h ${(Math.floor(metrics.uptime/60)%60)}m</div>
              <div class="metric"><strong>CPU Load</strong><br>${metrics.load.currentLoad.toFixed(1)}%</div>
            </div>
            <div class="raw">
              <details>
                <summary>Show raw data</summary>
                <pre>${JSON.stringify(metrics, null, 2)}</pre>
              </details>
            </div>
          </div>
        </body>
      </html>
  `);
 } catch (err) {
  res.status(500).send('Error fetching metrics from backend');
 }
});

app.listen(PORT, () => {
 console.log(`Frontend listening on port ${PORT}`);
});