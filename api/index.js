const express = require('express');
const path = require('path');
const app = express();
const port = 8080;

// Middleware to serve static files
app.use(express.static(path.join(__dirname, '../public')));

// Serve the index.html when visiting "/"
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../index.html'));
});

app.post('/api', (req, res) => {
  console.log("Received request:", req.body);
  res.json({ response: "yes" });
});

app.get('/api/status', (req, res) => {
  res.json({ status: "operational" });
});

app.listen(port, () => {
  console.log(`YaaS running at http://localhost:${port}`);
});

