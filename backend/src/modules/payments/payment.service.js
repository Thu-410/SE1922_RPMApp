const { pool } = require('../../config/db');
const AppError = require('../../utils/app-error');

const PAYMENT_METHODS = ['cash', 'bank_transfer', 'qr_code', 'momo', 'other'];

const positiveInteger = (value, field) => {
  const number = Number(value);
  if (!Number.isInteger(number) || number <= 0) throw new AppError(400, `${field} must be a positive integer`);
  return number;
};

const optionalPaymentDate = (value) => {
  if (value === undefined || value === null || value === '') return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) throw new AppError(400, 'paymentDate must be a valid date and time');
  return date.toISOString().slice(0, 19).replace('T', ' ');
};

const getPaymentById = async (id, connection = pool) => {
  const paymentId = positiveInteger(id, 'id');
  const [rows] = await connection.execute(
    `SELECT p.*, i.room_id, i.month, i.year, i.total_amount, i.status AS invoice_status,
            r.room_number, t.full_name AS tenant_name, u.full_name AS created_by_name
     FROM payments p
     JOIN invoices i ON i.id = p.invoice_id
     JOIN rooms r ON r.id = i.room_id
     JOIN tenants t ON t.id = i.tenant_id
     LEFT JOIN users u ON u.id = p.created_by
     WHERE p.id = ?`,
    [paymentId],
  );
  if (rows.length === 0) throw new AppError(404, 'Payment not found');
  return rows[0];
};

const listPayments = async (query) => {
  const page = Math.max(Number.parseInt(query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(Number.parseInt(query.limit, 10) || 20, 1), 100);
  const offset = (page - 1) * limit;
  const conditions = [];
  const params = [];

  if (query.invoiceId !== undefined) {
    conditions.push('p.invoice_id = ?');
    params.push(positiveInteger(query.invoiceId, 'invoiceId'));
  }
  if (query.paymentMethod !== undefined) {
    if (!PAYMENT_METHODS.includes(query.paymentMethod)) {
      throw new AppError(400, `paymentMethod must be one of: ${PAYMENT_METHODS.join(', ')}`);
    }
    conditions.push('p.payment_method = ?');
    params.push(query.paymentMethod);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const [counts] = await pool.execute(`SELECT COUNT(*) AS total FROM payments p ${where}`, params);
  const [rows] = await pool.execute(
    `SELECT p.*, r.room_number, t.full_name AS tenant_name, i.month, i.year,
            i.total_amount, i.status AS invoice_status
     FROM payments p
     JOIN invoices i ON i.id = p.invoice_id
     JOIN rooms r ON r.id = i.room_id
     JOIN tenants t ON t.id = i.tenant_id
     ${where}
     ORDER BY p.payment_date DESC, p.id DESC
     LIMIT ? OFFSET ?`,
    [...params, limit, offset],
  );
  const total = Number(counts[0].total);
  return { rows, meta: { page, limit, total, totalPages: Math.ceil(total / limit) } };
};

const getInvoicePayments = async (invoiceId) => {
  const normalizedInvoiceId = positiveInteger(invoiceId, 'invoiceId');
  const [invoices] = await pool.execute('SELECT id FROM invoices WHERE id = ?', [normalizedInvoiceId]);
  if (invoices.length === 0) throw new AppError(404, 'Invoice not found');
  const [rows] = await pool.execute(
    `SELECT p.*, u.full_name AS created_by_name
     FROM payments p
     LEFT JOIN users u ON u.id = p.created_by
     WHERE p.invoice_id = ?
     ORDER BY p.payment_date DESC, p.id DESC`,
    [normalizedInvoiceId],
  );
  return rows;
};

const createPayment = async (invoiceId, payload) => {
  const normalizedInvoiceId = positiveInteger(invoiceId, 'invoiceId');
  const paymentMethod = payload.paymentMethod || 'cash';
  if (!PAYMENT_METHODS.includes(paymentMethod)) {
    throw new AppError(400, `paymentMethod must be one of: ${PAYMENT_METHODS.join(', ')}`);
  }

  const transactionCode = payload.transactionCode?.trim() || null;
  if (transactionCode && transactionCode.length > 100) {
    throw new AppError(400, 'transactionCode cannot exceed 100 characters');
  }
  const paymentDate = optionalPaymentDate(payload.paymentDate);
  const createdBy = payload.createdBy == null ? null : positiveInteger(payload.createdBy, 'createdBy');
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const [invoices] = await connection.execute('SELECT * FROM invoices WHERE id = ? FOR UPDATE', [normalizedInvoiceId]);
    if (invoices.length === 0) throw new AppError(404, 'Invoice not found');
    const invoice = invoices[0];
    if (invoice.status === 'cancelled') throw new AppError(409, 'Cancelled invoice cannot be paid');
    if (invoice.status === 'paid') throw new AppError(409, 'Invoice has already been paid');

    const [totals] = await connection.execute(
      'SELECT COALESCE(SUM(amount), 0) AS paid_amount FROM payments WHERE invoice_id = ?',
      [normalizedInvoiceId],
    );
    const paidAmount = Number(totals[0].paid_amount);
    const remainingAmount = Math.round((Number(invoice.total_amount) - paidAmount) * 100) / 100;
    if (remainingAmount <= 0) throw new AppError(409, 'Invoice has no remaining balance');

    const amount = payload.amount === undefined ? remainingAmount : Number(payload.amount);
    if (!Number.isFinite(amount) || amount <= 0) throw new AppError(400, 'amount must be greater than zero');
    if (Math.abs(amount - remainingAmount) > 0.001) {
      throw new AppError(400, `Full payment of ${remainingAmount} is required`);
    }

    if (transactionCode) {
      const [duplicates] = await connection.execute(
        'SELECT id FROM payments WHERE transaction_code = ? LIMIT 1',
        [transactionCode],
      );
      if (duplicates.length > 0) throw new AppError(409, 'Transaction code already exists');
    }

    const [result] = await connection.execute(
      `INSERT INTO payments
       (invoice_id, amount, payment_method, transaction_code, payment_date, note, created_by)
       VALUES (?, ?, ?, ?, COALESCE(?, CURRENT_TIMESTAMP), ?, ?)`,
      [normalizedInvoiceId, remainingAmount, paymentMethod, transactionCode, paymentDate, payload.note || null, createdBy],
    );
    const [createdPayments] = await connection.execute('SELECT payment_date FROM payments WHERE id = ?', [result.insertId]);
    await connection.execute(
      `UPDATE invoices
       SET status = 'paid', paid_date = ?
       WHERE id = ?`,
      [createdPayments[0].payment_date, normalizedInvoiceId],
    );
    await connection.commit();
    return getPaymentById(result.insertId);
  } catch (error) {
    await connection.rollback();
    if (error.code === 'ER_NO_REFERENCED_ROW_2') throw new AppError(400, 'createdBy user does not exist');
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = { listPayments, getPaymentById, getInvoicePayments, createPayment };
