const express = require('express'); //import express
const si = require('systeminformation'); //import system information
const os = require('os'); //node build-in os module

const app = express();
const PORT = 5000; //port listen on

app.get('/metrics', async (req, res) => {
 //gather system info
 const mem = await si.mem();
 const cpu = await si.cpu();
 res.json({
  hostname: os.hostname(),
  os: os.type(),
  platform: os.platform(),
  uptime: os.uptime(),
  totalmem: mem.total,
  cpu: `${cpu.manufacturer} ${cpu.brand}`,
  cores: cpu.cores,
  load: await si.currentLoad(),
 });
});

app.get('/check', (req,res) => {
 console.log('Backend is running')
 res.send('Backend is running')
});

app.listen(PORT, () => {
 console.log(`Backend listening on port ${PORT}`);
});