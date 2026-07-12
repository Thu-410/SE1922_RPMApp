const assert = require('node:assert/strict');
const { once } = require('node:events');
const test = require('node:test');
const express = require('express');

const authRoutes = require('../src/modules/auth/auth.route');
const errorMiddleware = require('../src/middlewares/error.middleware');

test('register returns a correctly encoded Vietnamese error for an invalid phone', async () => {
  const app = express();
  app.use(express.json());
  app.use('/api/auth', authRoutes);
  app.use(errorMiddleware);

  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');

  try {
    const response = await fetch(`http://127.0.0.1:${server.address().port}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        full_name: 'Nguyễn Văn A',
        email: 'nguyen.van.a@example.com',
        password: 'abc123',
        phone: '1234567890',
      }),
    });
    const body = await response.json();

    assert.equal(response.status, 400);
    assert.deepEqual(body, {
      success: false,
      message: 'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0',
    });
  } finally {
    server.close();
    await once(server, 'close');
  }
});
