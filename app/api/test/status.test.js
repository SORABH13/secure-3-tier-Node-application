// test/status.test.js
// Run with: npx jest
//
// Mocks the 'pg' Pool so these tests run in CI without a real database.

jest.mock('pg', () => {
  const mPool = {
    connect: jest.fn((cb) => {
      const mClient = {
        query: jest.fn((sql, cb2) => {
          cb2(null, { rows: [{ time: '2026-08-07T00:00:00.000Z' }] });
        }),
      };
      cb(null, mClient, jest.fn()); // release()
    }),
    end: jest.fn(),
  };
  return { Pool: jest.fn(() => mPool) };
});

const request = require('supertest');
const app = require('../app');

describe('GET /api/status', () => {
  it('returns 200 and a row with a time field', async () => {
    const res = await request(app).get('/api/status');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toHaveProperty('time');
  });
});

describe('GET /unknown-route', () => {
  it('returns 404 for unmatched routes', async () => {
    const res = await request(app).get('/this-does-not-exist');
    expect(res.statusCode).toBe(404);
  });
});
