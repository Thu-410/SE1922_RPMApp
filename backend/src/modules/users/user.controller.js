const userService = require("./user.service");

const getMe = async (req, res, next) => {
    try {
        const user = await userService.getUserById(req.user.id);
        if (!user) {
            const error = new Error("Không tìm thấy tài khoản.");
            error.statusCode = 404;
            throw error;
        }
        return res.json({ success: true, data: user });
    } catch (error) {
        return next(error);
    }
};

const listUsers = async (req, res, next) => {
    try {
        return res.json({ success: true, data: await userService.getUsers() });
    } catch (error) {
        return next(error);
    }
};

module.exports = {
    getMe,
    listUsers
};
