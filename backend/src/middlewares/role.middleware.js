const requireRoles = (...allowedRoles) => (req, res, next) => {
    const roleName = req.user?.role_name?.trim().toLowerCase();
    if (roleName && allowedRoles.includes(roleName)) return next();

    const error = new Error("Bạn không có quyền thực hiện chức năng này.");
    error.statusCode = req.user ? 403 : 401;
    return next(error);
};

module.exports = {
    requireRoles
};
