const { pool } = require('../../config/db');
const AppError = require('../../utils/app-error');

const moneyFields = ['electricPrice', 'waterPrice', 'serviceFee', 'parkingFee', 'internetFee'];
const columnMap = {
  electricPrice: 'electric_price',
  waterPrice: 'water_price',
  serviceFee: 'service_fee',
  parkingFee: 'parking_fee',
  internetFee: 'internet_fee',
};

const parseMoney = (value, field) => {
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0) {
    throw new AppError(400, `${field} must be a non-negative number`);
  }
  return number;
};

const validateDate = (value) => {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value || '') || Number.isNaN(Date.parse(`${value}T00:00:00Z`))) {
    throw new AppError(400, 'effectiveDate must use YYYY-MM-DD format');
  }
  return value;
};

const parseBoolean = (value, field) => {
  if (value === true || value === 1 || value === '1' || value === 'true') return true;
  if (value === false || value === 0 || value === '0' || value === 'false') return false;
  throw new AppError(400, `${field} must be true or false`);
};

const getPrices = async () => {
  const [rows] = await pool.query('SELECT * FROM service_prices ORDER BY effective_date DESC, id DESC');
  return rows;
};

const getCurrentPrice = async () => {
  const [rows] = await pool.query(
    `SELECT * FROM service_prices
     WHERE is_active = TRUE AND effective_date <= CURDATE()
     ORDER BY effective_date DESC, id DESC
     LIMIT 1`,
  );
  if (rows.length === 0) throw new AppError(404, 'No active service price is available');
  return rows[0];
};

const createPrice = async (payload) => {
  const values = moneyFields.map((field) => parseMoney(payload[field], field));
  const effectiveDate = validateDate(payload.effectiveDate);
  const isActive = payload.isActive === undefined ? true : parseBoolean(payload.isActive, 'isActive');
  const [result] = await pool.execute(
    `INSERT INTO service_prices
     (electric_price, water_price, service_fee, parking_fee, internet_fee, effective_date, is_active)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [...values, effectiveDate, isActive],
  );
  return getPriceById(result.insertId);
};

const getPriceById = async (id) => {
  const priceId = Number(id);
  if (!Number.isInteger(priceId) || priceId <= 0) throw new AppError(400, 'id must be a positive integer');
  const [rows] = await pool.execute('SELECT * FROM service_prices WHERE id = ?', [priceId]);
  if (rows.length === 0) throw new AppError(404, 'Service price not found');
  return rows[0];
};

const updatePrice = async (id, payload) => {
  const current = await getPriceById(id);
  const assignments = [];
  const params = [];

  for (const field of moneyFields) {
    if (payload[field] !== undefined) {
      assignments.push(`${columnMap[field]} = ?`);
      params.push(parseMoney(payload[field], field));
    }
  }
  if (payload.effectiveDate !== undefined) {
    assignments.push('effective_date = ?');
    params.push(validateDate(payload.effectiveDate));
  }
  if (payload.isActive !== undefined) {
    assignments.push('is_active = ?');
    params.push(parseBoolean(payload.isActive, 'isActive'));
  }
  if (assignments.length === 0) return current;

  params.push(current.id);
  await pool.execute(`UPDATE service_prices SET ${assignments.join(', ')} WHERE id = ?`, params);
  return getPriceById(current.id);
};

module.exports = { getPrices, getCurrentPrice, getPriceById, createPrice, updatePrice };
