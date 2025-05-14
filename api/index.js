import express from 'express';
import serverless from 'serverless-http';

const app = express();
app.use(express.json());

// Health Check Route
app.get('/api/v1/health', (req, res) => {
  console.log('Health Check Invoked');
  try {
    res.status(200).json({ status: "YaaS Service is Running!" });
  } catch (error) {
    console.error('Error in health check:', error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Wrap express app in serverless-http and export the handler correctly
module.exports = app;
module.exports.handler = serverless(app);
