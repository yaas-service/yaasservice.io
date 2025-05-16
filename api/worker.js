
const express = require('express');
const app = express();
const port = 8080;

app.use(express.json());

app.post('/', (req, res) => {
  console.log("Received request:", req.body);
  res.json({ response: "yes" });
});

app.get('/status', (req, res) => {
  res.json({ status: "operational" });
});

app.listen(port, () => {
  console.log(`YaaS running at http://localhost:${port}`);
});
