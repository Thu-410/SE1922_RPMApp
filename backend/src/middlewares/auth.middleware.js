const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const AppError = require('../utils/app-error');

const getBearerToken = (authorizationHeader) => {
  if (!authorizationHeader) return null;
  const [scheme, token] = authorizationHeader.trim().split(/\s+/);
  if (scheme?.toLowerCase() !== 'bearer' || !token) return null;
  return token;
};

const authenticate = async (req, res, next) => {
  try {
    const token = getBearerToken(req.headers.authorization);
    if (!token) throw new AppError(401, 'Authentication token is required');
    if (!process.env.JWT_SECRET) throw new AppError(500, 'JWT_SECRET is not configured');

    let payload;
    try {
      payload = jwt.verify(token, process.env.JWT_SECRET, {
        algorithms: ['HS256'],
        issuer: process.env.JWT_ISSUER || 'rental-management-api',
      });
    } catch (error) {
      if (error.name === 'TokenExpiredError') throw new AppError(401, 'Authentication token has expired');
      throw new AppError(401, 'Authentication token is invalid');
    }

    const userId = Number(payload.sub ?? payload.userId ?? payload.id);
    if (!Number.isInteger(userId) || userId <= 0) throw new AppError(401, 'Authentication token is invalid');

    const [users] = await pool.execute(
      `SELECT u.id, u.full_name, u.email, u.phone, u.status,
              r.id AS role_id, r.name AS role
       FROM users u
       JOIN roles r ON r.id = u.role_id
       WHERE u.id = ?
       LIMIT 1`,
      [userId],
    );
    if (users.length === 0) throw new AppError(401, 'User account no longer exists');
    if (users[0].status !== 'active') throw new AppError(403, 'User account is not active');

    req.user = users[0];
    req.auth = payload;
    next();
  } catch (error) {
    next(error);
  }
};

module.exports = authenticate;
module.exports.authenticate = authenticate;
