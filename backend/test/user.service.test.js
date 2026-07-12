const assert = require('node:assert/strict');
const { beforeEach, test } = require('node:test');

const pool = require('../src/config/db');
const userService = require('../src/modules/users/user.service');

beforeEach(() => {
  pool.execute = async () => {
    throw new Error('Unexpected database query');
  };
});

test('POST /api/users rejects creating a manager', async () => {
  await assert.rejects(
    userService.createUser({
      full_name: 'New Manager',
      email: 'new-manager@example.com',
      password: '123456',
      role: 'manager',
    }),
    (err) => {
      assert.equal(err.statusCode, 400);
      assert.equal(err.message, "Chỉ có thể tạo tài khoản với vai trò 'staff' hoặc 'tenant'");
      return true;
    }
  );
});

test('POST /api/users returns a generated password with a security note', async () => {
  let queryIndex = 0;
  pool.execute = async (sql, params) => {
    queryIndex += 1;

    if (queryIndex === 1) {
      assert.equal(sql, 'SELECT id FROM users WHERE email = ? LIMIT 1');
      return [[]];
    }

    if (queryIndex === 2) {
      assert.equal(sql, 'SELECT id FROM roles WHERE name = ? LIMIT 1');
      return [[{ id: 3 }]];
    }

    if (queryIndex === 3) {
      assert.match(sql, /^INSERT INTO users/);
      assert.equal(params[0], 3);
      assert.notEqual(params[3], undefined);
      return [{ insertId: 10 }];
    }

    assert.match(sql, /WHERE users\.id = \?/);
    return [[{ id: 10, full_name: 'New Staff', role: 'staff', status: 'active' }]];
  };

  const result = await userService.createUser({
    full_name: 'New Staff',
    email: 'new-staff@example.com',
    role: 'staff',
  });

  assert.equal(typeof result.temporaryPassword, 'string');
  assert.ok(result.temporaryPassword.length > 0);
  assert.equal(
    result.note,
    'Vui lòng gửi mật khẩu này cho người dùng qua kênh an toàn và yêu cầu đổi ngay lần đăng nhập đầu.'
  );
});

test('PUT /api/users/:ownId rejects changing the manager own role', async () => {
  pool.execute = async (sql, params) => {
    assert.match(sql, /WHERE users\.id = \?/);
    assert.deepEqual(params, [1]);
    return [[{ id: 1, role: 'manager', status: 'active' }]];
  };

  await assert.rejects(
    userService.updateUser(
      1,
      { full_name: 'Manager', phone: null, role: 'tenant', status: 'active' },
      1
    ),
    (err) => {
      assert.equal(err.statusCode, 400);
      assert.equal(err.message, 'Không thể tự thay đổi vai trò của chính mình');
      return true;
    }
  );
});

test('PUT /api/users/:id allows a manager to change another user role', async () => {
  let queryIndex = 0;
  pool.execute = async (sql, params) => {
    queryIndex += 1;

    if (queryIndex === 1) {
      assert.match(sql, /WHERE users\.id = \?/);
      assert.deepEqual(params, [2]);
      return [[{ id: 2, full_name: 'Staff User', role: 'tenant', status: 'active' }]];
    }

    if (queryIndex === 2) {
      assert.equal(sql, 'SELECT id FROM roles WHERE name = ? LIMIT 1');
      assert.deepEqual(params, ['staff']);
      return [[{ id: 2 }]];
    }

    if (queryIndex === 3) {
      assert.match(sql, /^UPDATE users SET/);
      assert.deepEqual(params, ['Staff User', null, 2, 'active', 2]);
      return [{ affectedRows: 1 }];
    }

    assert.match(sql, /WHERE users\.id = \?/);
    assert.deepEqual(params, [2]);
    return [[{ id: 2, full_name: 'Staff User', role: 'staff', status: 'active' }]];
  };

  const user = await userService.updateUser(
    2,
    { full_name: 'Staff User', phone: null, role: 'staff', status: 'active' },
    1
  );

  assert.equal(user.role, 'staff');
  assert.equal(queryIndex, 4);
});
