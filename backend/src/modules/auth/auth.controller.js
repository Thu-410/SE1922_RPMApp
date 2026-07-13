const authService = require("./auth.service");

const login = async (req, res, next) => {
    try {
        const email = typeof req.body?.email === "string"
            ? req.body.email.trim().toLowerCase()
            : "";
        const password = typeof req.body?.password === "string"
            ? req.body.password
            : "";
        if (!email || !password) {
            const error = new Error("Email và mật khẩu là bắt buộc.");
            error.statusCode = 400;
            throw error;
        }
        if (email.length > 150 || password.length > 200) {
            const error = new Error("Thông tin đăng nhập không hợp lệ.");
            error.statusCode = 400;
            throw error;
        }

        const session = await authService.login(email, password);
        if (!session) {
            const error = new Error("Email hoặc mật khẩu không chính xác.");
            error.statusCode = 401;
            throw error;
        }
        return res.json({ success: true, data: session });
    } catch (error) {
        return next(error);
    }
};

module.exports = {
    login
};
