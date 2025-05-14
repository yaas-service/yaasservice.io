import express from 'express';
import { VercelRequest, VercelResponse } from '@vercel/node';

const app = express();
app.use(express.json());

// Health Check Route
app.get('/api/v1/health', (req, res) => {
  console.log('Health Check Invoked');
  res.status(200).json({ status: "YaaS Service is Running!" });
});

// Vercel Serverless Function Handler
export default (req, res) => {
  app(req, res);
};
