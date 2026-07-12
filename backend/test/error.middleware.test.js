const assert = require('node:assert/strict');
const { afterEach, beforeEach, test } = require('node:test');

const errorMiddleware = require('../src/middlewares/error.middleware');

const originalNodeEnv = process.env.NODE_ENV;
const originalConsoleError = console.error;
let loggedErrors;

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

beforeEach(() => {
  loggedErrors = [];
  console.error = (...args) => loggedErrors.push(args);
});

afterEach(() => {
  if (originalNodeEnv === undefined) {
    delete process.env.NODE_ENV;
  } else {
    process.env.NODE_ENV = originalNodeEnv;
  }
  console.error = originalConsoleError;
});

test('keeps safe business error messages', () => {
  process.env.NODE_ENV = 'production';
  const err = Object.assign(new Error('Không thể tự thay đổi vai trò của chính mình'), { statusCode: 400 });
  const res = createResponse();

  errorMiddleware(err, {}, res, () => {});

  assert.equal(res.statusCode, 400);
  assert.deepEqual(res.body, {
    success: false,
    message: 'Không thể tự thay đổi vai trò của chính mình',
  });
  assert.equal(loggedErrors[0][1], err);
});

test('hides internal error details in production', () => {
  process.env.NODE_ENV = 'production';
  const err = new Error('SELECT failed on secret_table at C:\\server\\db.js');
  const res = createResponse();

  errorMiddleware(err, {}, res, () => {});

  assert.equal(res.statusCode, 500);
  assert.deepEqual(res.body, {
    success: false,
    message: 'Đã xảy ra lỗi hệ thống, vui lòng thử lại sau.',
  });
  assert.equal(loggedErrors[0][1], err);
});

test('includes internal error details only in development', () => {
  process.env.NODE_ENV = 'development';
  const err = Object.assign(new Error('Database connection failed'), { statusCode: 500 });
  const res = createResponse();

  errorMiddleware(err, {}, res, () => {});

  assert.equal(res.statusCode, 500);
  assert.equal(res.body.message, 'Đã xảy ra lỗi hệ thống, vui lòng thử lại sau.');
  assert.equal(res.body.details, err.message);
  assert.equal(res.body.stack, err.stack);
});
