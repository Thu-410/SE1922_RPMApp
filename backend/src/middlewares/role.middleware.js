const { error } = require('../utils/response');

const checkRole = (...allowedRoles) => (req, res, next) => {
  if (!req.user || !allowedRoles.includes(req.user.role)) {
    return error(res, 'Không có quyền truy cập', 403);
  }

  return next();
};

module.exports = checkRole;
