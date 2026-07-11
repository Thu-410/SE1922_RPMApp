const mysql = require("mysql2/promise");

const pool = mysql.createPool({
    host: process.env.DB_HOST || "127.0.0.1",
    port: Number(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD || "root123",
    database: process.env.DB_NAME || "quan_ly_tro",
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    decimalNumbers: true
});

const connectDB = async () => {
    await pool.query("SELECT 1");
    console.log("Kết nối MySQL thành công");
    return pool;
};

module.exports = {
    pool,
    connectDB
};
