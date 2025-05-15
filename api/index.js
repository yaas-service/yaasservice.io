// Minimal API implementation
export default function handler(req, res) {
  // Simple health check endpoint
  if (req.url === '/api/v1/health') {
    return res.status(200).json({ 
      status: "Operational",
      version: "2.0.0"
    });
  }
  
  // For any other API endpoints
  return res.status(200).json({ 
    message: "YaaS API is running"
  });
}
