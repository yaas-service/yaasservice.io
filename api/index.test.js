import request from 'supertest';
import app from './index.js';

describe('GET /api/v1/health', () => {
  it('should return YaaS Service is Running', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual('YaaS Service is Running!');
  });
});
