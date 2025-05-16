#!/bin/bash
# yaas_deploy_final.sh - Corrected Deployment Script

# 1. Set these environment variables before running!
# export VERCEL_TOKEN="your_vercel_token"
# export CLOUDFLARE_TOKEN="your_cloudflare_token"

# 2. API Code Update
cat > api/index.js <<'EOL'
import express from 'express';
import serverless from 'serverless-http';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import rateLimit from 'express-rate-limit';
import { get } from '@vercel/edge-config';
import dotenv from 'dotenv';

dotenv.config();

const app = express();

app.use(cors({
  origin: ['https://yaasservice.io', 'http://localhost:3000'],
  methods: ['GET', 'POST', 'OPTIONS']
}));
app.use(express.json());

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
app.use(limiter);

// Health endpoint
app.get('/api/v1/health', (req, res) => {
  res.status(200).json({ 
    status: "Operational",
    version: "2.3.0",
    environment: process.env.NODE_ENV 
  });
});

// Auth endpoint
app.post('/api/v1/auth/token', async (req, res) => {
  try {
    const { apiKey } = req.body;
    const validKey = process.env.API_KEY || '673274006fb6b23dc18609e7beb4b1409cb157d373abc2322e5202b47604a2e2';
    
    if (apiKey !== validKey) {
      return res.status(401).json({ error: "Invalid API Key" });
    }

    const token = jwt.sign(
      { access: 'basic' },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '1h' }
    );

    res.json({ token, expiresIn: '1h' });
  } catch (error) {
    console.error('Auth error:', error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Analysis endpoint
app.post('/api/v1/analyze', (req, res) => {
  const { text } = req.body;
  if (!text) return res.status(400).json({ error: "Missing text" });
  
  res.json({
    analysisId: Date.now().toString(36),
    textLength: text.length,
    timestamp: new Date().toISOString()
  });
});

export default serverless(app);
EOL

# 3. Vercel Configuration
cat > vercel.json <<'EOL'
{
  "version": 2,
  "builds": [{
    "src": "api/index.js",
    "use": "@vercel/node"
  }],
  "routes": [
    {"src": "/api/.*", "dest": "api/index.js"},
    {"src": "/(.*)", "dest": "public/index.html"}
  ]
}
EOL

# 4. Deployment Process
echo "🚀 Starting deployment..."
rm -rf node_modules package-lock.json
npm install
vercel deploy --prod --token $VERCEL_TOKEN

# 5. Post-deploy verification
DEPLOY_URL=$(vercel ls --token $VERCEL_TOKEN | grep -o 'https://[^ ]*' | head -n1)

echo "🔍 Testing endpoints at $DEPLOY_URL"

echo "🩺 Health check:"
curl -s "$DEPLOY_URL/api/v1/health" | jq

echo "🔑 Auth test:"
curl -s -X POST "$DEPLOY_URL/api/v1/auth/token" \
  -H "Content-Type: application/json" \
  -d '{"apiKey":"673274006fb6b23dc18609e7beb4b1409cb157d373abc2322e5202b47604a2e2"}' | jq

echo "🧹 Purging Cloudflare cache..."
curl -X POST "https://api.cloudflare.com/client/v4/zones/a44048aba7521e90edbddbae88f94d89/purge_cache" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}' | jq '.success'

echo "✅ Deployment complete! Final URL: $DEPLOY_URL"
