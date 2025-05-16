// Simple in-memory rate limiter for serverless functions
const rateLimiter = () => {
  // In-memory store (note: this only works per instance in serverless)
  const ipStore = {};
  const windowMs = 15 * 60 * 1000; // 15 minutes
  const maxRequests = 100; // Max requests per windowMs
  
  return async (req, res, next) => {
    const ip = req.headers['x-forwarded-for'] || req.headers['x-real-ip'] || req.connection.remoteAddress;
    
    if (!ip) {
      return next();
    }
    
    // Initialize or clean expired requests
    const now = Date.now();
    if (!ipStore[ip] || (now - ipStore[ip].timestamp > windowMs)) {
      ipStore[ip] = {
        count: 1,
        timestamp: now
      };
      return next();
    }
    
    // Increment count for existing IPs
    ipStore[ip].count += 1;
    
    // Check if limit exceeded
    if (ipStore[ip].count > maxRequests) {
      return res.status(429).json({
        error: "Too many requests",
        message: "Please try again later"
      });
    }
    
    return next();
  };
};

export default rateLimiter;
