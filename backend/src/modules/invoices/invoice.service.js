const { pool } = require('../../config/db');
const AppError = require('../../utils/app-error');

const VALID_STATUSES = ['unpaid', 'paid', 'overdue', 'cancelled'];

const positiveInteger = (value, field) => {
  const number = Number(value);
  if (!Number.isInteger(number) || number <= 0) throw new AppError(400, `${field} must be a positive integer`);
  return number;
};

const nonNegativeMoney = (value, field, defaultValue = 0) => {
  if (value === undefined || value === null || value === '') return defaultValue;
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0) throw new AppError(400, `${field} must be a non-negative number`);
  return Math.round(number * 100) / 100;
};

const booleanValue = (value, field, defaultValue) => {
  if (value === undefined) return defaultValue;
  if (value === true || value === 1 || value === '1' || value === 'true') return true;
  if (value === false || value === 0 || value === '0' || value === 'false') return false;
  throw new AppError(400, `${field} must be true or false`);
};

const period = (month, year) => {
  const normalizedMonth = Number(month);
  const normalizedYear = Number(year);
  if (!Number.isInteger(normalizedMonth) || normalizedMonth < 1 || normalizedMonth > 12) {
    throw new AppError(400, 'month must be between 1 and 12');
  }
  if (!Number.isInteger(normalizedYear) || normalizedYear < 2020) {
    throw new AppError(400, 'year must be an integer greater than or equal to 2020');
  }
  const firstDay = `${normalizedYear}-${String(normalizedMonth).padStart(2, '0')}-01`;
  const lastDayDate = new Date(Date.UTC(normalizedYear, normalizedMonth, 0));
  const lastDay = lastDayDate.toISOString().slice(0, 10);
  return { month: normalizedMonth, year: normalizedYear, firstDay, lastDay };
};

const validDate = (value, field) => {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value || '')) throw new AppError(400, `${field} must use YYYY-MM-DD format`);
  const date = new Date(`${value}T00:00:00Z`);
  if (Number.isNaN(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new AppError(400, `${field} is not a valid date`);
  }
  return value;
};

const getCalculationSource = async (payload, connection = pool) => {
  const roomId = positiveInteger(payload.roomId, 'roomId');
  const invoicePeriod = period(payload.month, payload.year);

  const [rooms] = await connection.execute('SELECT * FROM rooms WHERE id = ?', [roomId]);
  if (rooms.length === 0) throw new AppError(404, 'Room not found');

  const [contracts] = await connection.execute(
    `SELECT c.*, t.full_name AS tenant_name, t.phone AS tenant_phone, t.email AS tenant_email
     FROM contracts c
     JOIN tenants t ON t.id = c.tenant_id
     WHERE c.room_id = ?
       AND c.status IN ('active', 'expired', 'terminated')
       AND c.start_date <= ?
       AND c.end_date >= ?
       AND (c.terminated_at IS NULL OR c.terminated_at >= ?)
     ORDER BY c.start_date DESC
     LIMIT 1`,
    [roomId, invoicePeriod.lastDay, invoicePeriod.firstDay, invoicePeriod.firstDay],
  );
  if (contracts.length === 0) throw new AppError(409, 'Không có hợp đồng có hiệu lực trong kỳ hóa đơn của phòng này');

  const [readings] = await connection.execute(
    `SELECT * FROM utility_readings
     WHERE room_id = ? AND month = ? AND year = ?
     LIMIT 1`,
    [roomId, invoicePeriod.month, invoicePeriod.year],
  );
  if (readings.length === 0) throw new AppError(409, 'Utility reading is required before creating an invoice');

  const [prices] = await connection.execute(
    `SELECT * FROM service_prices
     WHERE is_active = TRUE AND effective_date <= ?
     ORDER BY effective_date DESC, id DESC
     LIMIT 1`,
    [invoicePeriod.lastDay],
  );
  if (prices.length === 0) throw new AppError(409, 'No active service price applies to this billing period');

  const [accounts] = await connection.execute(
    `SELECT * FROM payment_accounts
     WHERE status = 'active'
     ORDER BY is_default DESC, id ASC
     LIMIT 1`,
  );

  return {
    room: rooms[0],
    contract: contracts[0],
    reading: readings[0],
    price: prices[0],
    paymentAccount: accounts[0] || null,
    invoicePeriod,
  };
};

const calculateInvoice = (source, payload) => {
  const includeService = booleanValue(payload.includeService, 'includeService', true);
  const includeParking = booleanValue(payload.includeParking, 'includeParking', false);
  const includeInternet = booleanValue(payload.includeInternet, 'includeInternet', true);
  const otherFee = nonNegativeMoney(payload.otherFee, 'otherFee');
  const discount = nonNegativeMoney(payload.discount, 'discount');

  const roomPrice = Number(source.contract.monthly_price);
  const electricUsage = Number(source.reading.electric_usage);
  const waterUsage = Number(source.reading.water_usage);
  const electricPrice = Number(source.price.electric_price);
  const waterPrice = Number(source.price.water_price);
  const electricFee = electricUsage * electricPrice;
  const waterFee = waterUsage * waterPrice;
  const serviceFee = includeService ? Number(source.price.service_fee) : 0;
  const parkingFee = includeParking ? Number(source.price.parking_fee) : 0;
  const internetFee = includeInternet ? Number(source.price.internet_fee) : 0;
  const subtotal = roomPrice + electricFee + waterFee + serviceFee + parkingFee + internetFee + otherFee;
  if (discount > subtotal) throw new AppError(400, 'discount cannot be greater than the invoice subtotal');
  const totalAmount = subtotal - discount;

  const label = `${String(source.invoicePeriod.month).padStart(2, '0')}/${source.invoicePeriod.year}`;
  const items = [
    { itemType: 'room', itemName: `Tiền phòng ${source.room.room_number} tháng ${label}`, quantity: 1, unitPrice: roomPrice, amount: roomPrice },
    { itemType: 'electric', itemName: `Tiền điện: ${electricUsage} số x ${electricPrice}`, quantity: electricUsage, unitPrice: electricPrice, amount: electricFee },
    { itemType: 'water', itemName: `Tiền nước: ${waterUsage} khối x ${waterPrice}`, quantity: waterUsage, unitPrice: waterPrice, amount: waterFee },
  ];
  if (serviceFee > 0) items.push({ itemType: 'service', itemName: 'Phí dịch vụ', quantity: 1, unitPrice: serviceFee, amount: serviceFee });
  if (parkingFee > 0) items.push({ itemType: 'parking', itemName: 'Phí gửi xe', quantity: 1, unitPrice: parkingFee, amount: parkingFee });
  if (internetFee > 0) items.push({ itemType: 'internet', itemName: 'Phí internet', quantity: 1, unitPrice: internetFee, amount: internetFee });
  if (otherFee > 0) items.push({ itemType: 'other', itemName: payload.otherFeeName || 'Phí khác', quantity: 1, unitPrice: otherFee, amount: otherFee });
  if (discount > 0) items.push({ itemType: 'other', itemName: 'Giảm giá', quantity: 1, unitPrice: -discount, amount: -discount });

  return {
    roomPrice,
    electricFee,
    waterFee,
    serviceFee,
    parkingFee,
    internetFee,
    otherFee,
    discount,
    subtotal,
    totalAmount,
    electricUsage,
    waterUsage,
    items,
  };
};

const replaceInvoiceDetails = async (connection, invoiceId, items) => {
  await connection.execute('DELETE FROM invoice_details WHERE invoice_id = ?', [invoiceId]);
  for (const item of items) {
    await connection.execute(
      `INSERT INTO invoice_details
       (invoice_id, item_type, item_name, quantity, unit_price, amount, note)
       VALUES (?, ?, ?, ?, ?, ?, NULL)`,
      [invoiceId, item.itemType, item.itemName, item.quantity, item.unitPrice, item.amount],
    );
  }
};

const previewInvoice = async (payload) => {
  const source = await getCalculationSource(payload);
  const calculation = calculateInvoice(source, payload);
  return { ...source, calculation };
};

const getInvoiceById = async (id, connection = pool) => {
  const invoiceId = positiveInteger(id, 'id');
  const [rows] = await connection.execute(
    `SELECT i.*, r.room_number, t.full_name AS tenant_name, t.phone AS tenant_phone,
            t.email AS tenant_email, pa.owner_name, pa.bank_name,
            pa.bank_account_number, pa.qr_image_url
     FROM invoices i
     JOIN rooms r ON r.id = i.room_id
     JOIN tenants t ON t.id = i.tenant_id
     LEFT JOIN payment_accounts pa ON pa.id = i.payment_account_id
     WHERE i.id = ?`,
    [invoiceId],
  );
  if (rows.length === 0) throw new AppError(404, 'Invoice not found');
  const [details] = await connection.execute(
    'SELECT * FROM invoice_details WHERE invoice_id = ? ORDER BY id ASC',
    [invoiceId],
  );
  const [payments] = await connection.execute(
    'SELECT * FROM payments WHERE invoice_id = ? ORDER BY payment_date DESC, id DESC',
    [invoiceId],
  );
  return { ...rows[0], details, payments };
};

const createInvoice = async (payload) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const source = await getCalculationSource(payload, connection);
    const calculation = calculateInvoice(source, payload);
    const dueDate = validDate(payload.dueDate, 'dueDate');
    if (dueDate < source.invoicePeriod.firstDay) throw new AppError(400, 'dueDate cannot be before the billing period');

    const [duplicates] = await connection.execute(
      'SELECT id FROM invoices WHERE room_id = ? AND month = ? AND year = ? LIMIT 1 FOR UPDATE',
      [source.room.id, source.invoicePeriod.month, source.invoicePeriod.year],
    );
    if (duplicates.length > 0) throw new AppError(409, 'Invoice already exists for this room and period');

    const createdBy = payload.createdBy == null ? null : positiveInteger(payload.createdBy, 'createdBy');
    const [result] = await connection.execute(
      `INSERT INTO invoices
       (room_id, tenant_id, contract_id, payment_account_id, month, year,
        room_price, electric_fee, water_fee, service_fee, parking_fee,
        internet_fee, other_fee, discount, total_amount, status, due_date,
        paid_date, note, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'unpaid', ?, NULL, ?, ?)`,
      [
        source.room.id, source.contract.tenant_id, source.contract.id,
        source.paymentAccount?.id || null, source.invoicePeriod.month, source.invoicePeriod.year,
        calculation.roomPrice, calculation.electricFee, calculation.waterFee,
        calculation.serviceFee, calculation.parkingFee, calculation.internetFee,
        calculation.otherFee, calculation.discount, calculation.totalAmount,
        dueDate, payload.note || null, createdBy,
      ],
    );

    await replaceInvoiceDetails(connection, result.insertId, calculation.items);

    await connection.commit();
    return getInvoiceById(result.insertId);
  } catch (error) {
    await connection.rollback();
    if (error.code === 'ER_DUP_ENTRY') throw new AppError(409, 'Invoice already exists for this room and period');
    throw error;
  } finally {
    connection.release();
  }
};

const updateInvoice = async (id, payload) => {
  const invoiceId = positiveInteger(id, 'id');
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [invoices] = await connection.execute('SELECT * FROM invoices WHERE id = ? FOR UPDATE', [invoiceId]);
    if (invoices.length === 0) throw new AppError(404, 'Invoice not found');
    const invoice = invoices[0];
    if (invoice.status !== 'unpaid') {
      throw new AppError(409, `Only unpaid invoices can be updated; current status is ${invoice.status}`);
    }

    const effectivePayload = {
      ...payload,
      roomId: invoice.room_id,
      month: invoice.month,
      year: invoice.year,
      includeService: payload.includeService ?? Number(invoice.service_fee) > 0,
      includeParking: payload.includeParking ?? Number(invoice.parking_fee) > 0,
      includeInternet: payload.includeInternet ?? Number(invoice.internet_fee) > 0,
      otherFee: payload.otherFee ?? Number(invoice.other_fee),
      discount: payload.discount ?? Number(invoice.discount),
    };
    const source = await getCalculationSource(effectivePayload, connection);
    if (source.contract.id !== invoice.contract_id || source.contract.tenant_id !== invoice.tenant_id) {
      throw new AppError(409, 'The active contract no longer matches the invoice');
    }
    const calculation = calculateInvoice(source, effectivePayload);
    const dueDate = payload.dueDate === undefined
      ? invoice.due_date
      : validDate(payload.dueDate, 'dueDate');
    if (dueDate < source.invoicePeriod.firstDay) throw new AppError(400, 'dueDate cannot be before the billing period');

    await connection.execute(
      `UPDATE invoices
       SET payment_account_id = ?, room_price = ?, electric_fee = ?, water_fee = ?,
           service_fee = ?, parking_fee = ?, internet_fee = ?, other_fee = ?,
           discount = ?, total_amount = ?, due_date = ?, note = ?
       WHERE id = ?`,
      [
        source.paymentAccount?.id || invoice.payment_account_id,
        calculation.roomPrice, calculation.electricFee, calculation.waterFee,
        calculation.serviceFee, calculation.parkingFee, calculation.internetFee,
        calculation.otherFee, calculation.discount, calculation.totalAmount,
        dueDate, payload.note ?? invoice.note, invoiceId,
      ],
    );
    await replaceInvoiceDetails(connection, invoiceId, calculation.items);
    await connection.commit();
    return getInvoiceById(invoiceId);
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const cancelInvoice = async (id, payload) => {
  const invoiceId = positiveInteger(id, 'id');
  const reason = payload.reason?.trim();
  if (!reason) throw new AppError(400, 'Cancellation reason is required');
  if (reason.length > 1000) throw new AppError(400, 'Cancellation reason cannot exceed 1000 characters');

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [invoices] = await connection.execute('SELECT * FROM invoices WHERE id = ? FOR UPDATE', [invoiceId]);
    if (invoices.length === 0) throw new AppError(404, 'Invoice not found');
    const invoice = invoices[0];
    if (invoice.status === 'paid') throw new AppError(409, 'Paid invoice cannot be cancelled');
    if (invoice.status === 'cancelled') throw new AppError(409, 'Invoice has already been cancelled');

    const [payments] = await connection.execute('SELECT id FROM payments WHERE invoice_id = ? LIMIT 1', [invoiceId]);
    if (payments.length > 0) throw new AppError(409, 'Invoice with payment history cannot be cancelled');

    const cancellationNote = invoice.note
      ? `${invoice.note}\n[CANCELLED] ${reason}`
      : `[CANCELLED] ${reason}`;
    await connection.execute(
      `UPDATE invoices
       SET status = 'cancelled', paid_date = NULL, note = ?
       WHERE id = ?`,
      [cancellationNote, invoiceId],
    );
    await connection.commit();
    return getInvoiceById(invoiceId);
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const markOverdueInvoices = async () => {
  const [result] = await pool.execute(
    `UPDATE invoices
     SET status = 'overdue'
     WHERE status = 'unpaid' AND due_date < CURDATE()`,
  );
  return { updatedCount: result.affectedRows };
};

const listInvoices = async (query) => {
  const page = Math.max(Number.parseInt(query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(Number.parseInt(query.limit, 10) || 20, 1), 100);
  const offset = (page - 1) * limit;
  const conditions = [];
  const params = [];

  if (query.roomId !== undefined) { conditions.push('i.room_id = ?'); params.push(positiveInteger(query.roomId, 'roomId')); }
  if (query.tenantId !== undefined) { conditions.push('i.tenant_id = ?'); params.push(positiveInteger(query.tenantId, 'tenantId')); }
  if (query.month !== undefined || query.year !== undefined) {
    const normalized = period(query.month, query.year);
    conditions.push('i.month = ?', 'i.year = ?');
    params.push(normalized.month, normalized.year);
  }
  if (query.status !== undefined) {
    if (!VALID_STATUSES.includes(query.status)) throw new AppError(400, `status must be one of: ${VALID_STATUSES.join(', ')}`);
    conditions.push('i.status = ?'); params.push(query.status);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const [counts] = await pool.execute(`SELECT COUNT(*) AS total FROM invoices i ${where}`, params);
  const [rows] = await pool.execute(
    `SELECT i.*, r.room_number, t.full_name AS tenant_name
     FROM invoices i
     JOIN rooms r ON r.id = i.room_id
     JOIN tenants t ON t.id = i.tenant_id
     ${where}
     ORDER BY i.year DESC, i.month DESC, r.room_number ASC
     LIMIT ? OFFSET ?`,
    [...params, limit, offset],
  );
  const total = Number(counts[0].total);
  return { rows, meta: { page, limit, total, totalPages: Math.ceil(total / limit) } };
};

const getTenantIdByUserId = async (userId) => {
  const [rows] = await pool.execute(
    'SELECT id FROM tenants WHERE user_id = ? LIMIT 1',
    [userId],
  );
  if (rows.length === 0) throw new AppError(404, 'Không có hồ sơ người thuê liên kết với tài khoản này');
  return rows[0].id;
};

const listMyInvoices = async (userId, query) => {
  const tenantId = await getTenantIdByUserId(userId);
  return listInvoices({ ...query, tenantId });
};

const getMyInvoiceById = async (userId, invoiceId) => {
  const tenantId = await getTenantIdByUserId(userId);
  const invoice = await getInvoiceById(invoiceId);
  if (invoice.tenant_id !== tenantId) throw new AppError(403, 'You cannot view this invoice');
  return invoice;
};

module.exports = {
  previewInvoice,
  createInvoice,
  updateInvoice,
  cancelInvoice,
  markOverdueInvoices,
  getInvoiceById,
  listInvoices,
  listMyInvoices,
  getMyInvoiceById,
};
