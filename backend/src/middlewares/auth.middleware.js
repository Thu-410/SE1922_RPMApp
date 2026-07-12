const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { error } = require('../utils/response');

const authMiddleware = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return error(res, 'Chưa đăng nhập', 401);
  }

  const token = authHeader.split(' ')[1];
  if (!token) {
    return error(res, 'Chưa đăng nhập', 401);
  }

  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    return error(res, 'Token không hợp lệ hoặc đã hết hạn', 401);
  }

  try {
    // Luôn query lại DB để tài khoản bị khóa hoặc role mới có hiệu lực ngay, không tin role/status cũ trong token.
    const [rows] = await pool.execute(
      `SELECT users.id, roles.name AS role, users.status
       FROM users
       JOIN roles ON users.role_id = roles.id
       WHERE users.id = ?
       LIMIT 1`,
      [decoded.id]
    );
    const user = rows[0];

    if (!user) {
      return error(res, 'Tài khoản không tồn tại', 401);
    }

    if (user.status !== 'active') {
      return error(res, 'Tài khoản đã bị khóa', 401);
    }

    req.user = {
      id: user.id,
      role: user.role,
      status: user.status,
    };

    return next();
  } catch (err) {
    return next(err);
  }
};

module.exports = authMiddleware;
