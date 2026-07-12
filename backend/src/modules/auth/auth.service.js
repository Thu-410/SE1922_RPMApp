const bcrypt = require('bcrypt');
const pool = require('../../config/db');
const generateToken = require('../../utils/generateToken');

const hashPassword = async (password) => {
  return bcrypt.hash(password, 10);
};

const comparePassword = async (password, hash) => {
  return bcrypt.compare(password, hash);
};

const getTenantRoleId = async () => {
  const [rows] = await pool.execute("SELECT id FROM roles WHERE name = 'tenant' LIMIT 1");

  if (!rows[0]) {
    const err = new Error('Tenant role not found');
    err.statusCode = 500;
    throw err;
  }

  return rows[0].id;
};

const registerUser = async ({ full_name, email, password, phone }) => {
  const [existingUsers] = await pool.execute('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);

  if (existingUsers.length > 0) {
    const err = new Error('Email already exists');
    err.statusCode = 409;
    throw err;
  }

  const roleId = await getTenantRoleId();
  const hashedPassword = await hashPassword(password);

  const [result] = await pool.execute(
    'INSERT INTO users (role_id, full_name, email, password, phone) VALUES (?, ?, ?, ?, ?)',
    [roleId, full_name, email, hashedPassword, phone]
  );

  return {
    id: result.insertId,
    full_name,
    email,
    phone,
    role: 'tenant',
  };
};

const loginUser = async (email, password) => {
  const [rows] = await pool.execute(
    `SELECT users.id, users.full_name, users.email, users.password, users.status, roles.name AS role
     FROM users
     JOIN roles ON users.role_id = roles.id
     WHERE users.email = ?
     LIMIT 1`,
    [email]
  );
  const user = rows[0];

  if (!user) {
    const err = new Error('Invalid email or password');
    err.statusCode = 401;
    throw err;
  }

  const isMatch = await comparePassword(password, user.password);
  if (!isMatch) {
    const err = new Error('Invalid email or password');
    err.statusCode = 401;
    throw err;
  }

  if (user.status !== 'active') {
    const err = new Error('Account is not active');
    err.statusCode = 403;
    throw err;
  }

  const token = generateToken({
    id: user.id,
    email: user.email,
    role: user.role,
  });

  return {
    token,
    user: {
      id: user.id,
      full_name: user.full_name,
      email: user.email,
      role: user.role,
    },
  };
};

const getProfile = async (userId) => {
  const [rows] = await pool.execute(
    `SELECT users.id, users.full_name, users.email, users.phone, users.status, roles.name AS role,
            users.created_at, users.updated_at
     FROM users
     JOIN roles ON users.role_id = roles.id
     WHERE users.id = ?
     LIMIT 1`,
    [userId]
  );

  if (!rows[0]) {
    const err = new Error('User not found');
    err.statusCode = 404;
    throw err;
  }

  return rows[0];
};

const updateProfile = async (userId, { full_name, phone }) => {
  const [existingUsers] = await pool.execute('SELECT id FROM users WHERE id = ? LIMIT 1', [userId]);

  if (!existingUsers[0]) {
    const err = new Error('User not found');
    err.statusCode = 404;
    throw err;
  }

  await pool.execute('UPDATE users SET full_name = ?, phone = ? WHERE id = ?', [full_name, phone, userId]);

  return getProfile(userId);
};

const changePassword = async (userId, oldPassword, newPassword) => {
  const [rows] = await pool.execute('SELECT id, password FROM users WHERE id = ? LIMIT 1', [userId]);
  const user = rows[0];

  if (!user) {
    const err = new Error('User not found');
    err.statusCode = 404;
    throw err;
  }

  const isMatch = await comparePassword(oldPassword, user.password);
  if (!isMatch) {
    const err = new Error('Old password is incorrect');
    err.statusCode = 400;
    throw err;
  }

  const hashedPassword = await hashPassword(newPassword);
  await pool.execute('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, userId]);

  return true;
};

module.exports = {
  hashPassword,
  comparePassword,
  registerUser,
  loginUser,
  getProfile,
  updateProfile,
  changePassword,
};
