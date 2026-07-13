const { pool } = require("../../config/db");

const USER_COLUMNS = `account.id, account.full_name, account.email, account.phone,
                      account.avatar_url, account.status, account.created_at,
                      account.updated_at, role.name AS role_name`;

const getUserById = async (id) => {
    const [rows] = await pool.execute(
        `SELECT ${USER_COLUMNS}
         FROM users AS account
         JOIN roles AS role ON role.id = account.role_id
         WHERE account.id = ?
         LIMIT 1`,
        [id]
    );
    return rows[0] || null;
};

const getUsers = async () => {
    const [rows] = await pool.execute(
        `SELECT ${USER_COLUMNS}
         FROM users AS account
         JOIN roles AS role ON role.id = account.role_id
         ORDER BY account.id ASC`
    );
    return rows;
};

module.exports = {
    getUserById,
    getUsers
};
