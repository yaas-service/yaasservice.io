// Environment variable configuration with defaults
const getEnv = (key, defaultValue = '') => {
  return process.env[key] || defaultValue;
};

export const NODE_ENV = getEnv('NODE_ENV', 'development');
export const JWT_SECRET = getEnv('JWT_SECRET', 'development-jwt-secret-do-not-use-in-production');
export const API_KEY = getEnv('API_KEY', 'development-api-key');
export const EDGE_CONFIG = getEnv('EDGE_CONFIG', '');
export const ENABLE_PREMIUM = getEnv('ENABLE_PREMIUM', 'false') === 'true';

// Export a validation function to check required environment variables
export const validateEnv = () => {
  const required = ['JWT_SECRET', 'API_KEY'];
  
  if (NODE_ENV === 'production') {
    required.push('EDGE_CONFIG');
  }
  
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    console.warn(`⚠️ Missing required environment variables: ${missing.join(', ')}`);
    return false;
  }
  
  return true;
};
