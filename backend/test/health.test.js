const request = require('supertest');
const { app } = require('../src/app');

describe('Health endpoints', () => {
  it('GET / should return healthy status', async () => {
    const res = await request(app).get('/');
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ status: 'healthy' });
  });
});
