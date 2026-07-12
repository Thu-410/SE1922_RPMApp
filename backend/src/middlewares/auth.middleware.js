function authMiddleware(req, res, next) {
    req.user = {
        id: Number(req.headers['x-user-id'] || 1),
        role: String(req.headers['x-user-role'] || 'Manager'),
        tenant_id: req.headers['x-tenant-id'] ? Number(req.headers['x-tenant-id']) : null,
    };
    next();
}

module.exports = authMiddleware;