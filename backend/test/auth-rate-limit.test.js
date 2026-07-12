const assert = require('node:assert/strict');
const { once } = require('node:events');
const test = require('node:test');
const express = require('express');
const jwt = require('jsonwebtoken');

const pool = require('../src/config/db');
const authRoutes = require('../src/modules/auth/auth.route');
const errorMiddleware = require('../src/middlewares/error.middleware');

const startServer = async () => {
  const app = express();
  app.use(express.json());
  app.use('/api/auth', authRoutes);
  app.use(errorMiddleware);

  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  return server;
};

test('login blocks the sixth failed request while profile remains unaffected', async () => {
  process.env.JWT_SECRET = 'auth-rate-limit-test-secret';
  pool.execute = async () => [[]];

  const server = await startServer();

  try {
    const baseUrl = `http://127.0.0.1:${server.address().port}`;

    for (let attempt = 1; attempt <= 5; attempt += 1) {
      const response = await fetch(`${baseUrl}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'unknown@example.com', password: 'wrong-password' }),
      });
      assert.equal(response.status, 401);
    }

    const blockedResponse = await fetch(`${baseUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'unknown@example.com', password: 'wrong-password' }),
    });
    const blockedBody = await blockedResponse.json();

    assert.equal(blockedResponse.status, 429);
    assert.match(blockedBody.message, /^Quá nhiều lần thử, vui lòng thử lại sau \d+ phút$/);

    pool.execute = async (sql) => {
      if (sql.includes('SELECT users.id, roles.name AS role')) {
        return [[{ id: 1, role: 'manager', status: 'active' }]];
      }

      return [[{
        id: 1,
        full_name: 'Manager',
        email: 'manager@example.com',
        role: 'manager',
        status: 'active',
      }]];
    };
    const token = jwt.sign({ id: 1 }, process.env.JWT_SECRET);

    for (let request = 1; request <= 6; request += 1) {
      const profileResponse = await fetch(`${baseUrl}/api/auth/profile`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      assert.equal(profileResponse.status, 200);
    }
  } finally {
    server.close();
    await once(server, 'close');
  }
});

test('register blocks the eleventh request', async () => {
  const server = await startServer();

  try {
    const url = `http://127.0.0.1:${server.address().port}/api/auth/register`;

    for (let attempt = 1; attempt <= 10; attempt += 1) {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
      assert.equal(response.status, 400);
    }

    const blockedResponse = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    const blockedBody = await blockedResponse.json();

    assert.equal(blockedResponse.status, 429);
    assert.match(blockedBody.message, /^Quá nhiều lần thử, vui lòng thử lại sau \d+ phút$/);
  } finally {
    server.close();
    await once(server, 'close');
  }
});
