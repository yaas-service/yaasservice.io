import express from 'express';
import serverless from 'serverless-http';

const app = express();
app.use(express.json());

// Health Check Route
app.get('/health', (req, res) => {
  console.log('Health Check Invoked');
  res.status(200).json({ status: "YaaS Service is Running!" });
});

// Export the serverless handler directly
module.exports = serverless(app);
