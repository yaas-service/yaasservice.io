import express from 'express';
import serverless from 'serverless-http';
import cors from 'cors';
import { get } from '@vercel/edge-config';
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

// Simple request logger middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  const method = req.method;
  const path = req.path;
  console.log(`${timestamp} - ${method} ${path}`);
  next();
});

// Core Service Endpoints
app.get('/api/v1/health', (req, res) => {
  console.log('Health Check Invoked');
  res.status(200).json({ 
    status: "Operational",
    version: "2.0.0",
    services: ["core", "edge-config"]
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
    console.error('Config error:', error);
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
    console.error('Analysis error:', error);
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

// IMPORTANT: This is the correct export format for Vercel serverless functions
export default function(req, res) {
  return serverless(app)(req, res);
}
