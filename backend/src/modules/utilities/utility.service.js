const { pool } = require('../../config/db');
const AppError = require('../../utils/app-error');

const toPositiveInteger = (value, fieldName) => {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new AppError(400, `${fieldName} must be a positive integer`);
  }
  return parsed;
};

const toNonNegativeInteger = (value, fieldName) => {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new AppError(400, `${fieldName} must be a non-negative integer`);
  }
  return parsed;
};

const normalizePeriod = (month, year) => {
  const normalizedMonth = Number(month);
  const normalizedYear = Number(year);

  if (!Number.isInteger(normalizedMonth) || normalizedMonth < 1 || normalizedMonth > 12) {
    throw new AppError(400, 'month must be between 1 and 12');
  }
  if (!Number.isInteger(normalizedYear) || normalizedYear < 2020) {
    throw new AppError(400, 'year must be an integer greater than or equal to 2020');
  }

  return { month: normalizedMonth, year: normalizedYear };
};

const assertRoomExists = async (roomId, connection = pool) => {
  const [rooms] = await connection.execute('SELECT id FROM rooms WHERE id = ?', [roomId]);
  if (rooms.length === 0) {
    throw new AppError(404, 'Room not found');
  }
};

const assertPeriodIsNotInvoiced = async (roomId, month, year, connection = pool) => {
  const [invoices] = await connection.execute(
    'SELECT id FROM invoices WHERE room_id = ? AND month = ? AND year = ? LIMIT 1',
    [roomId, month, year],
  );
  if (invoices.length > 0) {
    throw new AppError(409, 'Utility reading cannot be changed because an invoice already exists for this period');
  }
};

const findPreviousReading = async (roomId, month, year, connection = pool) => {
  const periodValue = year * 100 + month;
  const [rows] = await connection.execute(
    `SELECT new_electric, new_water
     FROM utility_readings
     WHERE room_id = ? AND (year * 100 + month) < ?
     ORDER BY year DESC, month DESC
     LIMIT 1`,
    [roomId, periodValue],
  );
  return rows[0] || null;
};

const getRoomOptions = async () => {
  const [rows] = await pool.query(
    `SELECT id, room_number, status, floor
     FROM rooms
     WHERE status NOT IN ('inactive', 'deleted')
     ORDER BY floor ASC, room_number ASC`,
  );
  return rows;
};

const listReadings = async (query) => {
  const page = Math.max(Number.parseInt(query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(Number.parseInt(query.limit, 10) || 20, 1), 100);
  const offset = (page - 1) * limit;
  const conditions = [];
  const params = [];

  if (query.roomId !== undefined) {
    conditions.push('ur.room_id = ?');
    params.push(toPositiveInteger(query.roomId, 'roomId'));
  }
  if (query.month !== undefined) {
    const period = normalizePeriod(query.month, query.year || 2020);
    conditions.push('ur.month = ?');
    params.push(period.month);
  }
  if (query.year !== undefined) {
    const year = Number(query.year);
    if (!Number.isInteger(year) || year < 2020) {
      throw new AppError(400, 'year must be an integer greater than or equal to 2020');
    }
    conditions.push('ur.year = ?');
    params.push(year);
  }

  const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const [countRows] = await pool.execute(
    `SELECT COUNT(*) AS total FROM utility_readings ur ${whereClause}`,
    params,
  );
  const [rows] = await pool.execute(
    `SELECT ur.*, r.room_number, u.full_name AS created_by_name
     FROM utility_readings ur
     JOIN rooms r ON r.id = ur.room_id
     LEFT JOIN users u ON u.id = ur.created_by
     ${whereClause}
     ORDER BY ur.year DESC, ur.month DESC, r.room_number ASC
     LIMIT ? OFFSET ?`,
    [...params, limit, offset],
  );

  const total = Number(countRows[0].total);
  return {
    rows,
    meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
  };
};

const getReadingById = async (id) => {
  const readingId = toPositiveInteger(id, 'id');
  const [rows] = await pool.execute(
    `SELECT ur.*, r.room_number, u.full_name AS created_by_name
     FROM utility_readings ur
     JOIN rooms r ON r.id = ur.room_id
     LEFT JOIN users u ON u.id = ur.created_by
     WHERE ur.id = ?`,
    [readingId],
  );
  if (rows.length === 0) throw new AppError(404, 'Utility reading not found');
  return rows[0];
};

const createReading = async (payload) => {
  const roomId = toPositiveInteger(payload.roomId, 'roomId');
  const { month, year } = normalizePeriod(payload.month, payload.year);
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    await assertRoomExists(roomId, connection);

    const [duplicates] = await connection.execute(
      'SELECT id FROM utility_readings WHERE room_id = ? AND month = ? AND year = ? LIMIT 1',
      [roomId, month, year],
    );
    if (duplicates.length > 0) throw new AppError(409, 'Utility reading already exists for this room and period');

    const previous = await findPreviousReading(roomId, month, year, connection);
    const oldElectric = payload.oldElectric === undefined
      ? previous?.new_electric
      : toNonNegativeInteger(payload.oldElectric, 'oldElectric');
    const oldWater = payload.oldWater === undefined
      ? previous?.new_water
      : toNonNegativeInteger(payload.oldWater, 'oldWater');

    if (oldElectric === undefined || oldWater === undefined) {
      throw new AppError(400, 'oldElectric and oldWater are required for the first reading of a room');
    }

    const newElectric = toNonNegativeInteger(payload.newElectric, 'newElectric');
    const newWater = toNonNegativeInteger(payload.newWater, 'newWater');
    if (newElectric < oldElectric) throw new AppError(400, 'newElectric cannot be less than oldElectric');
    if (newWater < oldWater) throw new AppError(400, 'newWater cannot be less than oldWater');

    const createdBy = payload.createdBy == null ? null : toPositiveInteger(payload.createdBy, 'createdBy');
    const [result] = await connection.execute(
      `INSERT INTO utility_readings
       (room_id, month, year, old_electric, new_electric, old_water, new_water, note, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [roomId, month, year, oldElectric, newElectric, oldWater, newWater, payload.note || null, createdBy],
    );
    await connection.commit();
    return getReadingById(result.insertId);
  } catch (error) {
    await connection.rollback();
    if (error.code === 'ER_DUP_ENTRY') throw new AppError(409, 'Utility reading already exists for this room and period');
    throw error;
  } finally {
    connection.release();
  }
};

const updateReading = async (id, payload) => {
  const readingId = toPositiveInteger(id, 'id');
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const [rows] = await connection.execute('SELECT * FROM utility_readings WHERE id = ? FOR UPDATE', [readingId]);
    if (rows.length === 0) throw new AppError(404, 'Utility reading not found');
    const current = rows[0];
    await assertPeriodIsNotInvoiced(current.room_id, current.month, current.year, connection);

    const oldElectric = payload.oldElectric === undefined ? current.old_electric : toNonNegativeInteger(payload.oldElectric, 'oldElectric');
    const newElectric = payload.newElectric === undefined ? current.new_electric : toNonNegativeInteger(payload.newElectric, 'newElectric');
    const oldWater = payload.oldWater === undefined ? current.old_water : toNonNegativeInteger(payload.oldWater, 'oldWater');
    const newWater = payload.newWater === undefined ? current.new_water : toNonNegativeInteger(payload.newWater, 'newWater');
    if (newElectric < oldElectric) throw new AppError(400, 'newElectric cannot be less than oldElectric');
    if (newWater < oldWater) throw new AppError(400, 'newWater cannot be less than oldWater');

    await connection.execute(
      `UPDATE utility_readings
       SET old_electric = ?, new_electric = ?, old_water = ?, new_water = ?, note = ?
       WHERE id = ?`,
      [oldElectric, newElectric, oldWater, newWater, payload.note ?? current.note, readingId],
    );
    await connection.commit();
    return getReadingById(readingId);
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const deleteReading = async (id) => {
  const readingId = toPositiveInteger(id, 'id');
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [rows] = await connection.execute('SELECT * FROM utility_readings WHERE id = ? FOR UPDATE', [readingId]);
    if (rows.length === 0) throw new AppError(404, 'Utility reading not found');
    const reading = rows[0];
    await assertPeriodIsNotInvoiced(reading.room_id, reading.month, reading.year, connection);
    await connection.execute('DELETE FROM utility_readings WHERE id = ?', [readingId]);
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = {
  getRoomOptions,
  listReadings,
  getReadingById,
  createReading,
  updateReading,
  deleteReading,
};
