const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'quan_ly_tro',
  waitForConnections: true,
  connectionLimit: Number(process.env.DB_CONNECTION_LIMIT || 10),
  queueLimit: 0,
  charset: 'utf8mb4',
  decimalNumbers: true,
  dateStrings: true,
});

const connectDB = async () => {
  const connection = await pool.getConnection();

  try {
    await connection.ping();
    console.log(`Connected to MySQL database "${process.env.DB_NAME || 'quan_ly_tro'}"`);
  } finally {
    connection.release();
  }

  return pool;
};

const closeDB = async () => {
  await pool.end();
};

module.exports = {
  pool,
  connectDB,
  closeDB,
};
