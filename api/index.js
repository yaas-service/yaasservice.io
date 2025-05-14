import express from 'express';
import serverless from 'serverless-http';

const app = express();

app.use(express.json());

// Health Check Route
app.get('/api/v1/health', (req, res) => {
  console.log('Health Check Invoked');
  res.status(200).json({ status: "YaaS Service is Running!" });
});

// Serverless Handler
export default serverless(app);
