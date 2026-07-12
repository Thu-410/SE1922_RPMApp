const crypto = require('crypto');
const bcrypt = require('bcrypt');
const pool = require('../../config/db');

const USER_SELECT = `SELECT users.id, users.full_name, users.email, users.phone, roles.name AS role,
                            users.status, users.created_at, users.updated_at
                     FROM users
                     JOIN roles ON users.role_id = roles.id`;

const hashPassword = async (password) => {
  return bcrypt.hash(password, 10);
};

const generateTemporaryPassword = () => {
  return crypto.randomBytes(6).toString('base64url');
};

const getRoleId = async (role) => {
  const [rows] = await pool.execute('SELECT id FROM roles WHERE name = ? LIMIT 1', [role]);

  if (!rows[0]) {
    const err = new Error('Invalid role');
    err.statusCode = 400;
    throw err;
  }

  return rows[0].id;
};

const buildUserFilters = ({ role, status, search }) => {
  const conditions = [];
  const params = [];

  if (role) {
    conditions.push('roles.name = ?');
    params.push(role);
  }

  if (status) {
    conditions.push('users.status = ?');
    params.push(status);
  }

  if (search) {
    conditions.push('(users.full_name LIKE ? OR users.email LIKE ?)');
    params.push(`%${search}%`, `%${search}%`);
  }

  return {
    whereSql: conditions.length ? `WHERE ${conditions.join(' AND ')}` : '',
    params,
  };
};

const getAllUsers = async (filters = {}) => {
  const page = Math.max(Number(filters.page) || 1, 1);
  const limit = Math.min(Math.max(Number(filters.limit) || 10, 1), 100);
  const offset = (page - 1) * limit;
  const { whereSql, params } = buildUserFilters(filters);

  const [users] = await pool.execute(
    `${USER_SELECT}
     ${whereSql}
     ORDER BY users.created_at DESC
     LIMIT ${limit} OFFSET ${offset}`,
    params
  );

  const [countRows] = await pool.execute(
    `SELECT COUNT(*) AS total
     FROM users
     JOIN roles ON users.role_id = roles.id
     ${whereSql}`,
    params
  );

  const total = countRows[0].total;

  return {
    users,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
};

const getUserById = async (id) => {
  const [rows] = await pool.execute(
    `${USER_SELECT}
     WHERE users.id = ?
     LIMIT 1`,
    [id]
  );

  if (!rows[0]) {
    const err = new Error('User not found');
    err.statusCode = 404;
    throw err;
  }

  return rows[0];
};

const createUser = async ({ full_name, email, password, phone, role = 'tenant', status = 'active' }) => {
  if (!['staff', 'tenant'].includes(role)) {
    const err = new Error("Chỉ có thể tạo tài khoản với vai trò 'staff' hoặc 'tenant'");
    err.statusCode = 400;
    throw err;
  }

  const [existingUsers] = await pool.execute('SELECT id FROM users WHERE email = ? LIMIT 1', [email]);

  if (existingUsers.length > 0) {
    const err = new Error('Email already exists');
    err.statusCode = 409;
    throw err;
  }

  const roleId = await getRoleId(role);
  const temporaryPassword = password || generateTemporaryPassword();
  const hashedPassword = await hashPassword(temporaryPassword);

  const [result] = await pool.execute(
    'INSERT INTO users (role_id, full_name, email, password, phone, status) VALUES (?, ?, ?, ?, ?, ?)',
    [roleId, full_name, email, hashedPassword, phone || null, status]
  );

  const user = await getUserById(result.insertId);

  return {
    user,
    temporaryPassword: password ? null : temporaryPassword,
    ...(password
      ? {}
      : {
          note: 'Vui lòng gửi mật khẩu này cho người dùng qua kênh an toàn và yêu cầu đổi ngay lần đăng nhập đầu.',
        }),
  };
};

const updateUser = async (id, data, currentUserId) => {
  const currentUser = await getUserById(id);

  if (Number(id) === Number(currentUserId)) {
    if (data.role !== currentUser.role) {
      const err = new Error('Không thể tự thay đổi vai trò của chính mình');
      err.statusCode = 400;
      throw err;
    }

    if (['inactive', 'locked'].includes(data.status)) {
      const err = new Error('Manager cannot lock or deactivate themself');
      err.statusCode = 400;
      throw err;
    }
  }

  const roleId = await getRoleId(data.role);

  await pool.execute(
    'UPDATE users SET full_name = ?, phone = ?, role_id = ?, status = ? WHERE id = ?',
    [data.full_name, data.phone || null, roleId, data.status, id]
  );

  return getUserById(id);
};

const deleteUser = async (id, currentUserId) => {
  await getUserById(id);

  if (Number(id) === Number(currentUserId)) {
    const err = new Error('Manager cannot delete themself');
    err.statusCode = 400;
    throw err;
  }

  await pool.execute("UPDATE users SET status = 'inactive' WHERE id = ?", [id]);

  return getUserById(id);
};

module.exports = {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
};
