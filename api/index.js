import express from 'express';
import serverless from 'serverless-http';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import rateLimit from 'express-rate-limit';
import { get } from '@vercel/edge-config';

const app = express();

// Security Middleware
app.use(cors({
  origin: [
    'https://yaasservice.io',
    'https://www.yaasservice.io',
    'https://*.vercel.app'
  ],
  methods: ['GET', 'POST', 'OPTIONS']
}));

app.use(express.json());

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  keyGenerator: (req) => req.headers['x-real-ip'] || req.ip,
  validate: { trustProxy: true }
});
app.use(limiter);

// JWT Configuration
const JWT_SECRET = process.env.JWT_SECRET;
const API_KEY = process.env.API_KEY;

// Production Endpoints
app.get('/api/v1/health', (req, res) => {
  res.status(200).json({ 
    status: "Operational",
    version: "2.2.0",
    environment: process.env.NODE_ENV
  });
});

app.post('/api/v1/auth/token', async (req, res) => {
  const { apiKey } = req.body;
  const validKey = await get('PROD_API_KEY');
  
  if (!apiKey || apiKey !== validKey) {
    return res.status(401).json({ error: "Invalid API Key" });
  }
  
  const token = jwt.sign({ 
    access: 'basic',
    exp: Math.floor(Date.now() / 1000) + (60 * 60)
  }, JWT_SECRET);
  
  res.json({ token });
});

app.post('/api/v1/analyze', (req, res) => {
  const { text } = req.body;
  if (!text) return res.status(400).json({ error: "Missing text" });
  
  res.json({
    analysis: "success",
    textLength: text.length,
    timestamp: new Date().toISOString(),
    premiumFeatures: process.env.ENABLE_PREMIUM === "true"
  });
});

export const handler = serverless(app);
