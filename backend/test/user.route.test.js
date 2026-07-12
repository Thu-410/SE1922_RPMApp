const assert = require('node:assert/strict');
const { once } = require('node:events');
const test = require('node:test');
const express = require('express');
const jwt = require('jsonwebtoken');

const pool = require('../src/config/db');
const userRoutes = require('../src/modules/users/user.route');
const errorMiddleware = require('../src/middlewares/error.middleware');

test('user routes reject invalid path and query parameters before querying user data', async () => {
  process.env.JWT_SECRET = 'user-route-test-secret';
  const token = jwt.sign({ id: 1, role: 'manager' }, process.env.JWT_SECRET);
  let databaseQueries = 0;

  pool.execute = async (sql, params) => {
    databaseQueries += 1;
    assert.match(sql, /WHERE users\.id = \?/);
    assert.deepEqual(params, [1]);
    return [[{ id: 1, role: 'manager', status: 'active' }]];
  };

  const app = express();
  app.use(express.json());
  app.use('/api/users', userRoutes);
  app.use(errorMiddleware);

  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');

  try {
    const port = server.address().port;

    for (const id of ['abc', '-1', '0']) {
      databaseQueries = 0;
      const response = await fetch(`http://127.0.0.1:${port}/api/users/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const body = await response.json();

      assert.equal(response.status, 400);
      assert.deepEqual(body, { success: false, message: 'ID không hợp lệ' });
      assert.equal(databaseQueries, 1, `ID ${id} must not reach the get-user database query`);
    }

    const invalidQueries = [
      ['page=0', 'page phải là số nguyên dương'],
      ['page=abc', 'page phải là số nguyên dương'],
      ['limit=0', 'limit phải là số nguyên từ 1 đến 100'],
      ['limit=101', 'limit phải là số nguyên từ 1 đến 100'],
      ['role=admin', 'role không hợp lệ'],
      ['status=deleted', 'status không hợp lệ'],
    ];

    for (const [queryString, expectedMessage] of invalidQueries) {
      databaseQueries = 0;
      const response = await fetch(`http://127.0.0.1:${port}/api/users?${queryString}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const body = await response.json();

      assert.equal(response.status, 400);
      assert.deepEqual(body, { success: false, message: expectedMessage });
      assert.equal(databaseQueries, 1, `${queryString} must not reach the list-users database query`);
    }
  } finally {
    server.close();
    await once(server, 'close');
  }
});
