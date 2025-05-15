import express from 'express';
import serverless from 'serverless-http';
import cors from 'cors';
import { get } from '@vercel/edge-config';
import rateLimit from 'express-rate-limit';
import crypto from 'crypto';

const app = express();

// Enhanced Middleware Stack
app.use(express.json());
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://yaasservice.io', 'https://www.yaasservice.io']
    : '*',
  methods: ['GET', 'POST', 'OPTIONS']
}));

app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
}));

app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Core Service Endpoints
app.get('/api/v1/health', (req, res) => {
  res.status(200).json({ 
    status: "Operational",
    version: "2.0.0",
    services: ["core", "edge-config", "rate-limiting"]
  });
});

app.get('/api/v1/config', async (req, res) => {
  try {
    const config = await get('appConfig');
    res.status(200).json({
      ...config,
      cacheStatus: "HIT",
      edge: true
    });
  } catch (error) {
    res.status(500).json({ 
      error: "Configuration Unavailable",
      edge: false,
      incidentId: crypto.randomUUID()
    });
  }
});

app.post('/api/v1/analyze', (req, res) => {
  try {
    const { data } = req.body;
    if (!data) {
      return res.status(400).json({ 
        error: "Bad Request",
        message: "Missing analysis data",
        incidentId: crypto.randomUUID()
      });
    }
    
    res.json({
      analysisId: crypto.randomUUID(),
      timestamp: new Date().toISOString(),
      insights: {
        wordCount: data.length,
        sentiment: "neutral"
      }
    });
  } catch (error) {
    res.status(500).json({
      error: "Analysis Failed",
      incidentId: crypto.randomUUID()
    });
  }
});

// Error Handling
app.use((err, req, res, next) => {
  console.error('🚨 Error:', err);
  res.status(500).json({
    error: "System Malfunction",
    incidentId: crypto.randomUUID()
  });
});

export const handler = serverless(app);
