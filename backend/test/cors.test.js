const assert = require('node:assert/strict');
const { afterEach, test } = require('node:test');

const corsConfigPath = require.resolve('../src/config/cors');
const originalAllowedOrigin = process.env.ALLOWED_ORIGIN;
const originalNodeEnv = process.env.NODE_ENV;

const restoreEnv = (name, value) => {
  if (value === undefined) {
    delete process.env[name];
  } else {
    process.env[name] = value;
  }
};

const loadCorsOptions = () => {
  delete require.cache[corsConfigPath];
  return require(corsConfigPath);
};

const isOriginAllowed = (corsOptions, origin) => new Promise((resolve, reject) => {
  corsOptions.origin(origin, (err, allowed) => {
    if (err) reject(err);
    else resolve(allowed);
  });
});

afterEach(() => {
  restoreEnv('ALLOWED_ORIGIN', originalAllowedOrigin);
  restoreEnv('NODE_ENV', originalNodeEnv);
  delete require.cache[corsConfigPath];
});

test('CORS uses the comma-separated ALLOWED_ORIGIN allowlist', async () => {
  process.env.NODE_ENV = 'production';
  process.env.ALLOWED_ORIGIN = 'https://app.example.com, https://admin.example.com';
  const corsOptions = loadCorsOptions();

  assert.equal(await isOriginAllowed(corsOptions, 'https://app.example.com'), true);
  assert.equal(await isOriginAllowed(corsOptions, 'https://admin.example.com'), true);
  assert.equal(await isOriginAllowed(corsOptions, 'https://evil.example.com'), false);
  assert.equal(await isOriginAllowed(corsOptions, undefined), true);
});

test('CORS allows localhost by default only outside production', async () => {
  delete process.env.ALLOWED_ORIGIN;
  process.env.NODE_ENV = 'development';
  let corsOptions = loadCorsOptions();

  assert.equal(await isOriginAllowed(corsOptions, 'http://localhost:5173'), true);
  assert.equal(await isOriginAllowed(corsOptions, 'http://127.0.0.1:8080'), true);
  assert.equal(await isOriginAllowed(corsOptions, 'https://evil.example.com'), false);

  process.env.NODE_ENV = 'production';
  corsOptions = loadCorsOptions();
  assert.equal(await isOriginAllowed(corsOptions, 'http://localhost:5173'), false);
});
