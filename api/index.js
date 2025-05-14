import express from 'express';
import { VercelRequest, VercelResponse } from '@vercel/node';

const app = express();
app.use(express.json());

app.get('/api/v1/health', (req, res) => {
  res.status(200).json({ status: "YaaS Service is Running!" });
});

// Vercel handler
export default (req, res) => {
  app(req, res);
};
