const bcrypt = require('bcryptjs');
const { pool } = require('../../config/db');
const AppError = require('../../utils/app-error');
const generateToken = require('../../utils/generateToken');

const normalizeEmail = (email) => String(email || '').trim().toLowerCase();

const validatePassword = (password, field = 'password') => {
  if (typeof password !== 'string' || password.length < 6) {
    throw new AppError(400, `${field === 'password' ? 'Mật khẩu' : 'Mật khẩu mới'} phải có ít nhất 6 ký tự`);
  }
};

const verifyAndUpgradePassword = async (user, password) => {
  const isHash = /^\$2[aby]\$/.test(user.password);
  const valid = isHash
    ? await bcrypt.compare(password, user.password)
    : password === user.password;

  if (valid && !isHash) {
    const hashedPassword = await bcrypt.hash(password, 10);
    await pool.execute('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, user.id]);
  }
  return valid;
};

const login = async ({ email, password }) => {
  const normalizedEmail = normalizeEmail(email);
  if (!normalizedEmail || !password) throw new AppError(400, 'Email và mật khẩu là bắt buộc');

  const [rows] = await pool.execute(
    `SELECT u.id, u.full_name, u.email, u.phone, u.password, u.status,
            r.name AS role
     FROM users u
     JOIN roles r ON r.id = u.role_id
     WHERE u.email = ?
     LIMIT 1`,
    [normalizedEmail],
  );
  const user = rows[0];
  if (!user || !(await verifyAndUpgradePassword(user, password))) {
    throw new AppError(401, 'Email hoặc mật khẩu không đúng');
  }
  if (user.status !== 'active') throw new AppError(403, 'Tài khoản không hoạt động');

  const safeUser = {
    id: user.id,
    full_name: user.full_name,
    email: user.email,
    phone: user.phone,
    role: user.role,
    status: user.status,
  };
  return { token: generateToken(safeUser), user: safeUser };
};

const register = async ({ full_name: fullName, email, password, phone }) => {
  const normalizedEmail = normalizeEmail(email);
  if (!String(fullName || '').trim()) throw new AppError(400, 'Họ tên là bắt buộc');
  if (!normalizedEmail.includes('@')) throw new AppError(400, 'Email không hợp lệ');
  if (!String(phone || '').trim()) throw new AppError(400, 'Số điện thoại là bắt buộc');
  validatePassword(password);

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [duplicates] = await connection.execute('SELECT id FROM users WHERE email = ? LIMIT 1', [normalizedEmail]);
    if (duplicates.length > 0) throw new AppError(409, 'Email đã tồn tại');
    const [roles] = await connection.execute("SELECT id FROM roles WHERE name = 'tenant' LIMIT 1");
    if (roles.length === 0) throw new AppError(500, 'Vai trò người thuê chưa được cấu hình');

    const hashedPassword = await bcrypt.hash(password, 10);
    const [result] = await connection.execute(
      'INSERT INTO users (role_id, full_name, email, password, phone, status) VALUES (?, ?, ?, ?, ?, \'active\')',
      [roles[0].id, fullName.trim(), normalizedEmail, hashedPassword, phone.trim()],
    );
    await connection.execute(
      `INSERT INTO tenants (user_id, full_name, phone, email, is_representative, status)
       VALUES (?, ?, ?, ?, FALSE, 'active')`,
      [result.insertId, fullName.trim(), phone.trim(), normalizedEmail],
    );
    await connection.commit();
    return { id: result.insertId, full_name: fullName.trim(), email: normalizedEmail, phone: phone.trim(), role: 'tenant', status: 'active' };
  } catch (error) {
    await connection.rollback();
    if (error.code === 'ER_DUP_ENTRY') throw new AppError(409, 'Email hoặc số CCCD đã tồn tại');
    throw error;
  } finally {
    connection.release();
  }
};

const getProfile = async (userId) => {
  const [rows] = await pool.execute(
    `SELECT u.id, u.full_name, u.email, u.phone, u.status, r.name AS role,
            u.created_at, u.updated_at
     FROM users u JOIN roles r ON r.id = u.role_id
     WHERE u.id = ? LIMIT 1`,
    [userId],
  );
  if (rows.length === 0) throw new AppError(404, 'Không tìm thấy tài khoản');
  return rows[0];
};

const updateProfile = async (userId, { full_name: fullName, phone }) => {
  if (!String(fullName || '').trim() || !String(phone || '').trim()) {
    throw new AppError(400, 'Họ tên và số điện thoại là bắt buộc');
  }
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.execute('UPDATE users SET full_name = ?, phone = ? WHERE id = ?', [fullName.trim(), phone.trim(), userId]);
    await connection.execute('UPDATE tenants SET full_name = ?, phone = ? WHERE user_id = ?', [fullName.trim(), phone.trim(), userId]);
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
  return getProfile(userId);
};

const changePassword = async (userId, oldPassword, newPassword) => {
  if (typeof oldPassword !== 'string' || oldPassword.length === 0) {
    throw new AppError(400, 'Mật khẩu hiện tại là bắt buộc');
  }
  validatePassword(newPassword, 'newPassword');
  const [rows] = await pool.execute('SELECT id, password FROM users WHERE id = ? LIMIT 1', [userId]);
  if (rows.length === 0) throw new AppError(404, 'Không tìm thấy tài khoản');
  if (!(await verifyAndUpgradePassword(rows[0], oldPassword))) throw new AppError(400, 'Mật khẩu hiện tại không đúng');
  await pool.execute('UPDATE users SET password = ? WHERE id = ?', [await bcrypt.hash(newPassword, 10), userId]);
};

module.exports = { login, register, getProfile, updateProfile, changePassword };
