const assert = require('node:assert/strict');
const test = require('node:test');

const authService = require('../src/modules/auth/auth.service');
const userService = require('../src/modules/users/user.service');
const authController = require('../src/modules/auth/auth.controller');
const userController = require('../src/modules/users/user.controller');

const createResponse = () => ({
  statusCode: null,
  body: null,
  status(code) {
    this.statusCode = code;
    return this;
  },
  json(body) {
    this.body = body;
    return this;
  },
});

test('register responds with 201 Created', async () => {
  authService.registerUser = async () => ({ id: 1 });
  const res = createResponse();

  await authController.register({ body: {} }, res, assert.fail);

  assert.equal(res.statusCode, 201);
  assert.equal(res.body.success, true);
});

test('create user responds with 201 Created', async () => {
  userService.createUser = async () => ({ user: { id: 2 } });
  const res = createResponse();

  await userController.createUser({ body: {} }, res, assert.fail);

  assert.equal(res.statusCode, 201);
  assert.equal(res.body.success, true);
});

test('soft-delete user consistently responds with 200 and a confirmation body', async () => {
  userService.deleteUser = async () => ({ id: 2, status: 'inactive' });
  const res = createResponse();

  await userController.deleteUser(
    { params: { id: 2 }, user: { id: 1 } },
    res,
    assert.fail
  );

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.message, 'Delete user successfully');
  assert.deepEqual(res.body.data, { id: 2, status: 'inactive' });
});
