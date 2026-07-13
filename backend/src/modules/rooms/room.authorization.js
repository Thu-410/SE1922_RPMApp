const { pool } = require("../../config/db");

const ROOM_ACTIONS = Object.freeze({
    LIST: "list",
    DETAIL: "detail",
    CREATE: "create",
    UPDATE: "update",
    DELETE: "delete",
    UPDATE_STATUS: "update_status"
});

// Điểm cấu hình duy nhất khi cần đổi quyền sau khi merge module auth/roles.
const ROOM_ROLE_POLICY = Object.freeze({
    [ROOM_ACTIONS.LIST]: ["manager", "staff", "tenant"],
    [ROOM_ACTIONS.DETAIL]: ["manager", "staff", "tenant"],
    [ROOM_ACTIONS.CREATE]: ["manager"],
    [ROOM_ACTIONS.UPDATE]: ["manager"],
    [ROOM_ACTIONS.DELETE]: ["manager"],
    [ROOM_ACTIONS.UPDATE_STATUS]: ["manager", "staff"]
});

const normalizeRoleName = (value) =>
    typeof value === "string" && value.trim()
        ? value.trim().toLowerCase()
        : null;

const resolveRoleName = async (user) => {
    const directRole =
        normalizeRoleName(user.role_name) ||
        normalizeRoleName(user.roleName) ||
        normalizeRoleName(user.role?.name) ||
        normalizeRoleName(typeof user.role === "string" ? user.role : null);
    if (directRole) return directRole;

    if (user.role_id || user.roleId) {
        const [roles] = await pool.execute(
            "SELECT name FROM roles WHERE id = ? LIMIT 1",
            [user.role_id || user.roleId]
        );
        return normalizeRoleName(roles[0]?.name);
    }

    if (user.id) {
        const [users] = await pool.execute(
            `SELECT role.name
             FROM users AS account
             JOIN roles AS role ON role.id = account.role_id
             WHERE account.id = ?
             LIMIT 1`,
            [user.id]
        );
        return normalizeRoleName(users[0]?.name);
    }

    return null;
};

const createAuthorizationError = (statusCode, message) => {
    const error = new Error(message);
    error.statusCode = statusCode;
    return error;
};

const authorizeRoomAction = (action) => async (req, res, next) => {
    try {
        if (!req.user) {
            return next(createAuthorizationError(401, "Vui lòng đăng nhập."));
        }

        const roleName = await resolveRoleName(req.user);
        if (!roleName) {
            return next(
                createAuthorizationError(
                    403,
                    "Tài khoản chưa được gán vai trò hợp lệ."
                )
            );
        }

        req.user.role_name = roleName;
        const allowedRoles = ROOM_ROLE_POLICY[action] || [];
        if (!allowedRoles.includes(roleName)) {
            return next(
                createAuthorizationError(
                    403,
                    "Bạn không có quyền thực hiện chức năng này."
                )
            );
        }

        return next();
    } catch (error) {
        return next(error);
    }
};

module.exports = {
    ROOM_ACTIONS,
    ROOM_ROLE_POLICY,
    authorizeRoomAction
};
