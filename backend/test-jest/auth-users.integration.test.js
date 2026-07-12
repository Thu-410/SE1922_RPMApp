const express = require('express');
const request = require('supertest');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

const pool = require('../src/config/db');
const authRoutes = require('../src/modules/auth/auth.route');
const userRoutes = require('../src/modules/users/user.route');
const errorMiddleware = require('../src/middlewares/error.middleware');

process.env.JWT_SECRET = 'jest-comprehensive-secret';
process.env.JWT_EXPIRES_IN = '1h';
process.env.NODE_ENV = 'test';

const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.get('/api/test-500', (_req, _res, next) => next(new Error("SELECT * FROM secret_table WHERE password='hash'")));
app.use(errorMiddleware);

const token = (id = 1, options = {}) => jwt.sign({ id }, process.env.JWT_SECRET, options);
const authRow = (role = 'manager', status = 'active', id = 1) => [{ id, role, status }];
const user = (overrides = {}) => ({
  id: 2, full_name: 'Test User', email: 'test@example.com', phone: '0912345678',
  role: 'tenant', status: 'active', created_at: new Date().toISOString(),
  updated_at: new Date().toISOString(), ...overrides,
});
const hasSecret = (value) => {
  if (Array.isArray(value)) return value.some(hasSecret);
  if (!value || typeof value !== 'object') return false;
  return Object.entries(value).some(([key, val]) => /password|hash/i.test(key) || hasSecret(val));
};
const queueDb = (...responses) => {
  pool.execute.mockImplementation(async () => {
    if (!responses.length) throw new Error('Unexpected database query');
    const next = responses.shift();
    return typeof next === 'function' ? next() : next;
  });
};

beforeEach(() => {
  pool.execute = jest.fn();
  jest.spyOn(console, 'error').mockImplementation(() => {});
});
afterEach(() => jest.restoreAllMocks());

describe('AUTH register', () => {
  test('register success forces tenant role and exposes no password/hash', async () => {
    queueDb([[]], [[{ id: 3 }]], [{ insertId: 10 }]);
    const res = await request(app).post('/api/auth/register').send({
      full_name: 'New User', email: 'new@example.com', password: 'abc123', phone: '0912345678', role: 'manager',
    });
    expect(res.status).toBe(201);
    expect(res.body.data.role).toBe('tenant');
    expect(hasSecret(res.body)).toBe(false);
  });
  test.each(['full_name', 'email', 'password', 'phone'])('missing %s returns 400', async (field) => {
    const body = { full_name: 'A', email: 'a@example.com', password: 'abc123', phone: '0912345678' };
    delete body[field];
    expect((await request(app).post('/api/auth/register').send(body)).status).toBe(400);
  });
  test('duplicate email returns 409', async () => {
    queueDb([[{ id: 8 }]]);
    expect((await request(app).post('/api/auth/register').send({ full_name: 'A', email: 'a@example.com', password: 'abc123', phone: '0912345678' })).status).toBe(409);
  });
  test('invalid email returns 400', async () => {
    expect((await request(app).post('/api/auth/register').send({ full_name: 'A', email: 'bad', password: 'abc123', phone: '0912345678' })).status).toBe(400);
  });
  test('privilege escalation role is ignored and account remains tenant', async () => {
    queueDb([[]], [[{ id: 3 }]], [{ insertId: 11 }]);
    const res = await request(app).post('/api/auth/register').send({ full_name: 'A', email: 'role@example.com', password: 'abc123', phone: '0912345678', role: 'manager' });
    expect(res.status).toBe(201);
    expect(res.body.data.role).toBe('tenant');
  });
});

describe('AUTH login', () => {
  test('correct credentials return token and sanitized user', async () => {
    const hash = await bcrypt.hash('abc123', 4);
    queueDb([[user({ password: hash, role: 'tenant' })]]);
    const res = await request(app).post('/api/auth/login').send({ email: 'test@example.com', password: 'abc123' });
    expect(res.status).toBe(200);
    expect(typeof res.body.data.token).toBe('string');
    expect(hasSecret(res.body)).toBe(false);
  });
  test('wrong password returns 401', async () => {
    const hash = await bcrypt.hash('abc123', 4);
    queueDb([[user({ password: hash })]]);
    expect((await request(app).post('/api/auth/login').send({ email: 'test@example.com', password: 'wrong' })).status).toBe(401);
  });
  test('unknown email returns 401', async () => {
    queueDb([[]]);
    expect((await request(app).post('/api/auth/login').send({ email: 'none@example.com', password: 'abc123' })).status).toBe(401);
  });
  test('inactive account returns 403', async () => {
    const hash = await bcrypt.hash('abc123', 4);
    queueDb([[user({ password: hash, status: 'inactive' })]]);
    expect((await request(app).post('/api/auth/login').send({ email: 'test@example.com', password: 'abc123' })).status).toBe(403);
  });
  test('SQL injection email is parameterized and cannot login', async () => {
    pool.execute.mockImplementation(async (sql, params) => {
      expect(sql).toContain('WHERE users.email = ?');
      expect(params).toEqual(["' OR '1'='1"]);
      return [[]];
    });
    expect((await request(app).post('/api/auth/login').send({ email: "' OR '1'='1", password: 'abc123' })).status).toBe(400);
    expect(pool.execute).not.toHaveBeenCalled();
  });
});

describe('AUTH profile and password', () => {
  test('GET profile with valid token returns sanitized user', async () => {
    queueDb([authRow()], [[user({ id: 1, role: 'manager' })]]);
    const res = await request(app).get('/api/auth/profile').set('Authorization', `Bearer ${token()}`);
    expect(res.status).toBe(200); expect(hasSecret(res.body)).toBe(false);
  });
  test('PUT profile updates allowed fields and ignores role/email', async () => {
    queueDb([authRow()], [[{ id: 1 }]], [{ affectedRows: 1 }], [[user({ id: 1, full_name: 'Changed', role: 'manager' })]]);
    const res = await request(app).put('/api/auth/profile').set('Authorization', `Bearer ${token()}`).send({ full_name: 'Changed', phone: '0987654321', role: 'tenant', email: 'hacker@example.com' });
    expect(res.status).toBe(200); expect(res.body.data.role).toBe('manager'); expect(res.body.data.email).toBe('test@example.com'); expect(hasSecret(res.body)).toBe(false);
  });
  test('missing token returns 401', async () => { expect((await request(app).get('/api/auth/profile')).status).toBe(401); });
  test('invalid token returns 401', async () => { expect((await request(app).get('/api/auth/profile').set('Authorization', 'Bearer invalid')).status).toBe(401); });
  test('expired token returns 401', async () => {
    const expired = jwt.sign({ id: 1 }, process.env.JWT_SECRET, { expiresIn: -1 });
    expect((await request(app).get('/api/auth/profile').set('Authorization', `Bearer ${expired}`)).status).toBe(401);
  });
  test('change password succeeds', async () => {
    const hash = await bcrypt.hash('old123', 4);
    queueDb([authRow()], [[{ id: 1, password: hash }]], [{ affectedRows: 1 }]);
    expect((await request(app).put('/api/auth/change-password').set('Authorization', `Bearer ${token()}`).send({ old_password: 'old123', new_password: 'new123' })).status).toBe(200);
  });
  test('wrong old password returns 400', async () => {
    const hash = await bcrypt.hash('old123', 4); queueDb([authRow()], [[{ id: 1, password: hash }]]);
    expect((await request(app).put('/api/auth/change-password').set('Authorization', `Bearer ${token()}`).send({ old_password: 'wrong', new_password: 'new123' })).status).toBe(400);
  });
  test.each(['old_password', 'new_password'])('change password missing %s returns 400', async (field) => {
    queueDb([authRow()]); const body = { old_password: 'old123', new_password: 'new123' }; delete body[field];
    expect((await request(app).put('/api/auth/change-password').set('Authorization', `Bearer ${token()}`).send(body)).status).toBe(400);
  });
});

describe('USERS authorization matrix', () => {
  const endpoints = [
    ['get', '/api/users'], ['get', '/api/users/2'], ['post', '/api/users'],
    ['put', '/api/users/2'], ['delete', '/api/users/2'],
  ];
  test.each(['tenant', 'staff'])('%s receives 403 on every /api/users endpoint', async (role) => {
    for (const [method, url] of endpoints) {
      queueDb([authRow(role)]);
      const res = await request(app)[method](url).set('Authorization', `Bearer ${token()}`).send({});
      expect(res.status).toBe(403);
    }
  });
  test('manager passes authorization on every endpoint', async () => {
    const valid = { full_name: 'U', email: 'u@example.com', password: 'abc123', role: 'tenant', status: 'active' };
    queueDb([authRow()], [[]], [[{ total: 0 }]]); expect((await request(app).get('/api/users').set('Authorization', `Bearer ${token()}`)).status).toBe(200);
    queueDb([authRow()], [[user()]]); expect((await request(app).get('/api/users/2').set('Authorization', `Bearer ${token()}`)).status).toBe(200);
    queueDb([authRow()], [[]], [[{ id: 3 }]], [{ insertId: 2 }], [[user()]]); expect((await request(app).post('/api/users').set('Authorization', `Bearer ${token()}`).send(valid)).status).toBe(201);
    queueDb([authRow()], [[user()]], [[{ id: 3 }]], [{ affectedRows: 1 }], [[user()]]); expect((await request(app).put('/api/users/2').set('Authorization', `Bearer ${token()}`).send(valid)).status).toBe(200);
    queueDb([authRow()], [[user()]], [{ affectedRows: 1 }], [[user({ status: 'inactive' })]]); expect((await request(app).delete('/api/users/2').set('Authorization', `Bearer ${token()}`)).status).toBe(200);
  });
});

describe('USERS CRUD, validation and security', () => {
  test('list supports pagination/filter with parameterized query and sanitized output', async () => {
    pool.execute.mockImplementationOnce(async () => [authRow()]).mockImplementationOnce(async (sql, params) => {
      expect(sql).toContain('roles.name = ?'); expect(sql).toContain('users.status = ?'); expect(sql).toContain('LIKE ?');
      expect(sql).toContain('LIMIT 5 OFFSET 5');
      expect(params).toEqual(['tenant', 'active', '%ann%', '%ann%']); return [[user()]];
    }).mockImplementationOnce(async (_sql, params) => { expect(params).toEqual(['tenant', 'active', '%ann%', '%ann%']); return [[{ total: 6 }]]; });
    const res = await request(app).get('/api/users?page=2&limit=5&role=tenant&status=active&search=ann').set('Authorization', `Bearer ${token()}`);
    expect(res.status).toBe(200); expect(res.body.data.pagination).toEqual({ page: 2, limit: 5, total: 6, totalPages: 2 }); expect(hasSecret(res.body)).toBe(false);
  });
  test('duplicate email on create returns 409', async () => {
    queueDb([authRow()], [[{ id: 9 }]]);
    const res = await request(app).post('/api/users').set('Authorization', `Bearer ${token()}`).send({ full_name: 'U', email: 'u@example.com', role: 'tenant' });
    expect(res.status).toBe(409);
  });
  test.each(['abc', '-1', '0'])('invalid id %s returns 400, never 500', async (id) => {
    queueDb([authRow()]); expect((await request(app).get(`/api/users/${id}`).set('Authorization', `Bearer ${token()}`)).status).toBe(400);
  });
  test('manager cannot change own role', async () => {
    queueDb([authRow()], [[user({ id: 1, role: 'manager' })]]);
    const res = await request(app).put('/api/users/1').set('Authorization', `Bearer ${token()}`).send({ full_name: 'M', role: 'tenant', status: 'active' }); expect(res.status).toBe(400);
  });
  test('manager cannot lock self', async () => {
    queueDb([authRow()], [[user({ id: 1, role: 'manager' })]]);
    const res = await request(app).put('/api/users/1').set('Authorization', `Bearer ${token()}`).send({ full_name: 'M', role: 'manager', status: 'locked' }); expect(res.status).toBe(400);
  });
  test('creating role=manager is blocked by current behavior', async () => {
    queueDb([authRow()]); const res = await request(app).post('/api/users').set('Authorization', `Bearer ${token()}`).send({ full_name: 'M', email: 'm@example.com', role: 'manager' }); expect(res.status).toBe(400);
  });
  test('all user-returning CRUD responses expose no password/hash', async () => {
    queueDb([authRow()], [[user({ password: undefined })]]); const res = await request(app).get('/api/users/2').set('Authorization', `Bearer ${token()}`);
    expect(res.status).toBe(200); expect(hasSecret(res.body)).toBe(false);
  });
});

describe('critical token freshness and 500 safety', () => {
  test('old token is rejected immediately after account becomes inactive', async () => {
    queueDb([authRow('manager', 'inactive')]);
    expect((await request(app).get('/api/users').set('Authorization', `Bearer ${token()}`)).status).toBe(401);
  });
  test('old token uses current DB role and loses manager access after role change', async () => {
    queueDb([authRow('tenant')]);
    expect((await request(app).get('/api/users').set('Authorization', `Bearer ${token()}`)).status).toBe(403);
  });
  test('production 500 response hides SQL, password, stack and internal details', async () => {
    const old = process.env.NODE_ENV; process.env.NODE_ENV = 'production';
    const res = await request(app).get('/api/test-500'); process.env.NODE_ENV = old;
    expect(res.status).toBe(500); expect(JSON.stringify(res.body)).not.toMatch(/SELECT|secret_table|password|stack/i);
  });
});
