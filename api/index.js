import express from 'express';
import { VercelRequest, VercelResponse } from '@vercel/node';

const app = express();

app.use(express.json());

// Health Check Route
app.get('/api/v1/health', (req, res) => {
  console.log('Health Check Invoked');
  res.status(200).json({ status: "YaaS Service is Running!" });
});

// Export the app to be used as a Vercel serverless function
export default (req, res) => {
  app(req, res);
};
