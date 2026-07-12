function roleMiddleware(...allowedRoles) {
    return (req, res, next) => {
        const currentRole = String(req.user?.role || '').toLowerCase();
        const allowed = allowedRoles.map((role) => String(role).toLowerCase());

        if (!currentRole || !allowed.includes(currentRole)) {
            return res.status(403).json({
                success: false,
                message: 'Bạn không có quyền thực hiện chức năng này',
            });
        }

        next();
    };
}

module.exports = roleMiddleware;