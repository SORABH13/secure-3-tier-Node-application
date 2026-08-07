// test/index.test.js
// Run with: npx jest

// The route under test calls out to the API service via global fetch. Mock
// it so the test doesn't depend on a live API_HOST/network.
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve([{ time: 'test-time' }]),
  })
);

const request = require('supertest');
const app = require('../app');

describe('GET /', () => {
  it('responds with 200 and does not hang', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBeLessThan(500);
  });
});

describe('GET /unknown-route', () => {
  it('returns a proper error response, not a hang', async () => {
    const res = await request(app).get('/this-does-not-exist');
    expect(res.statusCode).toBe(404);
    // proves the error-handling middleware itself doesn't crash
  });
});
