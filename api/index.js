// YaaS Service API - v2.3.2
// Simple serverless implementation optimized for Vercel

// Helper function for CORS headers
function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

// Simple sentiment analysis function
function analyzeSentiment(text) {
  const positiveWords = ['good', 'great', 'excellent', 'awesome', 'love', 'happy'];
  const negativeWords = ['bad', 'terrible', 'awful', 'hate', 'sad'];
  
  const words = text.toLowerCase().split(/\s+/);
  let positiveCount = 0;
  let negativeCount = 0;
  
  words.forEach(word => {
    if (positiveWords.includes(word)) positiveCount++;
    if (negativeWords.includes(word)) negativeCount++;
  });
  
  let sentiment = 'neutral';
  if (positiveCount > negativeCount) sentiment = 'positive';
  if (negativeCount > positiveCount) sentiment = 'negative';
  
  return {
    sentiment,
    stats: {
      wordCount: words.length,
      positiveWords: positiveCount,
      negativeWords: negativeCount
    }
  };
}

// Main serverless handler
export default async function handler(req, res) {
  // Set CORS headers for all responses
  setCorsHeaders(res);
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  
  // Parse the URL path
  const url = new URL(req.url, `https://${req.headers.host || 'localhost'}`);
  const path = url.pathname;
  
  // Health Check Endpoint
  if (path === '/api/v1/health' && req.method === 'GET') {
    return res.status(200).json({
      status: "Operational",
      version: "2.3.2",
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
      const { text } = JSON.parse(data);
      
      if (!text) {
        return res.status(400).json({ error: "Missing text parameter" });
      }
      
      // Generate analysis
      const analysis = analyzeSentiment(text);
      
      return res.status(200).json({
        analysisId: Date.now().toString(36),
        timestamp: new Date().toISOString(),
        textLength: text.length,
        analysis
      });
    } catch (error) {
      return res.status(500).json({ 
        error: "Analysis failed",
        message: error.message
      });
    }
  }
  
  // Default response for other API routes
  if (path.startsWith('/api/')) {
    return res.status(404).json({ 
      error: "Endpoint not found",
      availableEndpoints: [
        "/api/v1/health",
        "/api/v1/analyze"
      ]
    });
  }
  
  // Default static file handler
  return res.status(200).json({ message: "YaaS API is running" });
}
