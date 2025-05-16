#!/bin/bash
# enhance_yaas.sh - Enhance YaaS Service 

echo "🚀 Enhancing YaaS Service..."

# Create improved API implementation
mkdir -p api
cat > api/index.js <<EOL
// YaaS Service API - Enhanced Version v2.4.0

// Enhanced sentiment analysis with weights and more keywords
function analyzeSentiment(text) {
  // Expanded word lists with weights
  const sentimentWords = {
    positive: {
      'love': 3, 'excellent': 3, 'amazing': 3, 'outstanding': 3, 'perfect': 3,
      'great': 2, 'good': 2, 'awesome': 2, 'wonderful': 2, 'fantastic': 2,
      'nice': 1, 'happy': 1, 'pleased': 1, 'enjoy': 1, 'like': 1, 'helpful': 1
    },
    negative: {
      'hate': 3, 'terrible': 3, 'awful': 3, 'horrible': 3, 'disgusting': 3,
      'bad': 2, 'poor': 2, 'disappointing': 2, 'frustrated': 2, 'annoyed': 2,
      'dislike': 1, 'sad': 1, 'unhappy': 1, 'mediocre': 1, 'boring': 1
    }
  };
  
  // Handle negation words
  const negationWords = ['not', 'no', "don't", "doesn't", "didn't", "won't", "wouldn't", "can't", "couldn't"];
  
  // Text normalization
  const normalizedText = text.toLowerCase()
    .replace(/[.,\/#!$%\^&\*;:{}=\-_\`~()]/g, '')
    .replace(/\s{2,}/g, ' ');
  
  const words = normalizedText.split(' ');
  
  let positiveScore = 0;
  let negativeScore = 0;
  let positiveCount = 0;
  let negativeCount = 0;
  
  // Analyze sentiment
  for (let i = 0; i < words.length; i++) {
    const word = words[i];
    
    // Check for negation
    const isNegated = i > 0 && negationWords.includes(words[i-1]);
    
    // Check positive words
    if (sentimentWords.positive[word]) {
      if (isNegated) {
        negativeScore += sentimentWords.positive[word];
        negativeCount++;
      } else {
        positiveScore += sentimentWords.positive[word];
        positiveCount++;
      }
    }
    
    // Check negative words
    if (sentimentWords.negative[word]) {
      if (isNegated) {
        positiveScore += sentimentWords.negative[word];
        positiveCount++;
      } else {
        negativeScore += sentimentWords.negative[word];
        negativeCount++;
      }
    }
  }
  
  // Determine overall sentiment
  let sentiment = 'neutral';
  if (positiveScore > negativeScore) sentiment = 'positive';
  if (negativeScore > positiveScore) sentiment = 'negative';
  
  // Calculate confidence
  const totalScore = positiveScore + negativeScore;
  const confidence = totalScore > 0 
    ? Math.abs(positiveScore - negativeScore) / totalScore
    : 0;
  
  return {
    sentiment,
    confidence: parseFloat(confidence.toFixed(2)),
    stats: {
      wordCount: words.length,
      positiveWords: positiveCount,
      negativeWords: negativeCount,
      positiveScore,
      negativeScore
    }
  };
}

// Helper for CORS headers
function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

// Main serverless handler
export default async function handler(req, res) {
  // Set CORS headers
  setCorsHeaders(res);
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  
  // Parse URL path
  const url = new URL(req.url, \`https://\${req.headers.host || 'localhost'}\`);
  const path = url.pathname;
  
  // Health Check Endpoint
  if (path === '/api/v1/health' && req.method === 'GET') {
    return res.status(200).json({
      status: "Operational",
      version: "2.4.0",
      features: ["enhanced-sentiment-analysis", "negation-detection"],
      services: ["analysis", "health"]
    });
  }
  
  // Text Analysis Endpoint
  if (path === '/api/v1/analyze' && req.method === 'POST') {
    try {
      // Read request body
      const buffers = [];
      for await (const chunk of req) {
        buffers.push(chunk);
      }
      const data = Buffer.concat(buffers).toString();
      const parsedData = JSON.parse(data);
      
      // Validate request
      if (!parsedData.text) {
        return res.status(400).json({ 
          error: "Missing text parameter",
          message: "The 'text' field is required for analysis"
        });
      }
      
      // Text length check
      if (parsedData.text.length > 5000) {
        return res.status(400).json({ 
          error: "Text too long",
          message: "Text must be 5000 characters or less"
        });
      }
      
      // Generate analysis
      const analysis = analyzeSentiment(parsedData.text);
      
      // Generate unique ID
      const analysisId = Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
      
      return res.status(200).json({
        analysisId,
        timestamp: new Date().toISOString(),
        textLength: parsedData.text.length,
        analysis
      });
    } catch (error) {
      console.error("Analysis error:", error);
      return res.status(500).json({ 
        error: "Analysis failed",
        message: error.message
      });
    }
  }
  
  // Default response for API routes
  if (path.startsWith('/api/')) {
    return res.status(404).json({ 
      error: "Endpoint not found",
      availableEndpoints: [
        "/api/v1/health",
        "/api/v1/analyze"
      ]
    });
  }
  
  // Default response
  return res.status(200).json({ message: "YaaS API is running" });
}
EOL

# Create Vercel configuration
cat > vercel.json <<EOL
{
  "version": 2,
  "routes": [
    { "src": "/api/(.*)", "dest": "/api/index.js" },
    { "src": "/", "dest": "/public/index.html" }
  ],
  "functions": {
    "api/index.js": {
      "memory": 1024,
      "maxDuration": 5
    }
  }
}
EOL

# Deploy to Vercel
echo "🚀 Deploying to Vercel..."
vercel deploy --prod

echo "✅ YaaS Service Enhanced!"
