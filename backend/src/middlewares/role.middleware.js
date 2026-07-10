const AppError = require('../utils/app-error');

const authorizeRoles = (...allowedRoles) => {
  const normalizedRoles = allowedRoles.flat().map((role) => String(role).toLowerCase());

  return (req, res, next) => {
    if (!req.user) return next(new AppError(401, 'Authentication is required'));
    if (!normalizedRoles.includes(req.user.role.toLowerCase())) {
      return next(new AppError(403, 'You do not have permission to perform this action'));
    }
    return next();
  };
};

module.exports = authorizeRoles;
module.exports.authorizeRoles = authorizeRoles;
