const sql = require('mssql');
const dotenv = require('dotenv');

dotenv.config();

const config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER || 'localhost',
    database: process.env.DB_NAME,
    options: {
        encrypt: false,
        trustServerCertificate: true,
    },
};

let pool;

const connectDB = async () => {
    if (!pool) {
        pool = await sql.connect(config);
        console.log('Connected to SQL Server!');
    }
    return pool;
};

/**
 * Helper chạy query với positional params (?) giống MySQL.
 * Tự động convert ? → @p0, @p1, ... để dùng với mssql.
 * Trả về [recordset, result] để giữ nguyên cú pháp destructuring cũ.
 */
async function query(sqlText, params = []) {
    const db = await connectDB();
    const request = db.request();

    let i = 0;
    const converted = sqlText.replace(/\?/g, () => {
        const name = `p${i}`;
        const value = params[i];
        if (value === null || value === undefined) {
            request.input(name, sql.NVarChar, null);
        } else if (typeof value === 'number') {
            if (Number.isInteger(value)) {
                request.input(name, sql.Int, value);
            } else {
                request.input(name, sql.Decimal(18, 4), value);
            }
        } else {
            request.input(name, value);
        }
        i++;
        return `@${name}`;
    });

    const result = await request.query(converted);
    // Trả về [recordset, result] để `const [rows] = await query(...)` và
    // `const [[row]] = await query(...)` vẫn hoạt động đúng
    return [result.recordset, result];
}

module.exports = { sql, connectDB, query };