const authService = require("../modules/auth/auth.service");

const unauthorized = (message = "Vui lòng đăng nhập.") => {
    const error = new Error(message);
    error.statusCode = 401;
    return error;
};

const authenticate = async (req, res, next) => {
    const authorization = req.get("authorization");
    const match = authorization?.match(/^Bearer\s+(.+)$/i);
    if (!match) return next(unauthorized());

    let tokenIdentity;
    try {
        tokenIdentity = authService.verifyToken(match[1]);
    } catch (_) {
        return next(unauthorized("Phiên đăng nhập không hợp lệ hoặc đã hết hạn."));
    }

    try {
        const currentIdentity = await authService.getActiveIdentity(tokenIdentity.id);
        if (!currentIdentity) return next(unauthorized());
        req.user = currentIdentity;
        return next();
    } catch (error) {
        return next(error);
    }
};

module.exports = {
    authenticate
};
