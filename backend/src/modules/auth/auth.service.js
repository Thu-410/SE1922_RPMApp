const crypto = require("node:crypto");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { pool } = require("../../config/db");

const developmentSecret = crypto.randomBytes(48).toString("hex");

const getJwtSecret = () => {
    if (process.env.JWT_SECRET) return process.env.JWT_SECRET;
    if (process.env.NODE_ENV === "production") {
        const error = new Error("JWT_SECRET là bắt buộc trong môi trường production.");
        error.code = "AUTH_CONFIG_ERROR";
        throw error;
    }
    return developmentSecret;
};

const publicUser = (row) => ({
    id: row.id,
    full_name: row.full_name,
    email: row.email,
    phone: row.phone,
    avatar_url: row.avatar_url,
    status: row.status,
    role_name: row.role_name
});

const hashPassword = (password) => bcrypt.hash(password, 12);

const verifyPassword = async (password, storedPassword) => {
    if (typeof storedPassword !== "string" || !storedPassword) return false;
    if (storedPassword.startsWith("$2")) {
        return bcrypt.compare(password, storedPassword);
    }

    const supplied = Buffer.from(password);
    const stored = Buffer.from(storedPassword);
    return supplied.length === stored.length && crypto.timingSafeEqual(supplied, stored);
};

const login = async (email, password) => {
    const [rows] = await pool.execute(
        `SELECT account.id, account.full_name, account.email, account.password,
                account.phone, account.avatar_url, account.status,
                role.name AS role_name
         FROM users AS account
         JOIN roles AS role ON role.id = account.role_id
         WHERE account.email = ?
         LIMIT 1`,
        [email]
    );
    const account = rows[0];
    if (!account || account.status !== "active") return null;
    if (!(await verifyPassword(password, account.password))) return null;

    // Tự nâng cấp dữ liệu demo/legacy đang lưu mật khẩu dạng text.
    if (!account.password.startsWith("$2")) {
        await pool.execute("UPDATE users SET password = ? WHERE id = ?", [
            await hashPassword(password),
            account.id
        ]);
    }

    const user = publicUser(account);
    const token = jwt.sign(
        { sub: String(user.id), role_name: user.role_name },
        getJwtSecret(),
        {
            algorithm: "HS256",
            expiresIn: process.env.JWT_EXPIRES_IN || "8h",
            issuer: "rpmapp-backend",
            audience: "rpmapp-client"
        }
    );
    return { token, user };
};

const verifyToken = (token) => {
    const payload = jwt.verify(token, getJwtSecret(), {
        algorithms: ["HS256"],
        issuer: "rpmapp-backend",
        audience: "rpmapp-client"
    });
    const id = Number(payload.sub);
    if (!Number.isInteger(id) || id <= 0 || typeof payload.role_name !== "string") {
        throw new Error("Token không hợp lệ.");
    }
    return { id, role_name: payload.role_name };
};

const getActiveIdentity = async (id) => {
    const [rows] = await pool.execute(
        `SELECT account.id, role.name AS role_name
         FROM users AS account
         JOIN roles AS role ON role.id = account.role_id
         WHERE account.id = ? AND account.status = 'active'
         LIMIT 1`,
        [id]
    );
    return rows[0] || null;
};

const upgradeLegacyPasswords = async () => {
    const [rows] = await pool.execute(
        "SELECT id, password FROM users WHERE password NOT LIKE '$2%'"
    );
    for (const account of rows) {
        await pool.execute("UPDATE users SET password = ? WHERE id = ?", [
            await hashPassword(account.password),
            account.id
        ]);
    }
};

const validateAuthConfig = () => {
    getJwtSecret();
};

module.exports = {
    hashPassword,
    login,
    verifyToken,
    validateAuthConfig,
    getActiveIdentity,
    upgradeLegacyPasswords
};
