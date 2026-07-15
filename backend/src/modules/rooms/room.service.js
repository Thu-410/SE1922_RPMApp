const { pool } = require('../../config/db');
const AppError = require('../../utils/app-error');
const fs = require('fs/promises');
const path = require('path');
const crypto = require('crypto');

const ROOM_STATUSES = ['available', 'occupied', 'maintenance', 'inactive'];

const parseId = (value) => {
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0) throw new AppError(400, 'Mã phòng không hợp lệ');
  return id;
};

const validate = (body, partial = false) => {
  const data = {};
  const required = (key) => !partial || Object.prototype.hasOwnProperty.call(body, key);
  if (required('room_number')) {
    const value = body.room_number?.toString().trim();
    if (!value || value.length > 50) throw new AppError(400, 'Số phòng là bắt buộc và tối đa 50 ký tự');
    data.room_number = value;
  }
  for (const [key, label, integer] of [['floor', 'Tầng', true], ['area', 'Diện tích', false], ['price', 'Giá phòng', false], ['deposit', 'Tiền cọc', false]]) {
    if (!required(key)) continue;
    const value = Number(body[key]);
    if (!Number.isFinite(value) || value < 0 || (integer && !Number.isInteger(value))) {
      throw new AppError(400, `${label} phải là số không âm hợp lệ`);
    }
    data[key] = value;
  }
  if (required('status')) {
    if (!ROOM_STATUSES.includes(body.status)) throw new AppError(400, 'Trạng thái phòng không hợp lệ');
    data.status = body.status;
  }
  for (const key of ['description', 'image_url']) {
    if (!required(key)) continue;
    const value = body[key]?.toString().trim() || null;
    if (key === 'image_url' && value && value.length > 500) throw new AppError(400, 'Đường dẫn ảnh tối đa 500 ký tự');
    data[key] = value;
  }
  return data;
};

const getById = async (value, executor = pool) => {
  const id = parseId(value);
  const [rows] = await executor.execute(
    `SELECT r.*,
      (SELECT COUNT(*) FROM tenants t WHERE t.room_id = r.id AND t.status = 'active') AS active_tenant_count,
      (SELECT COUNT(*) FROM contracts c WHERE c.room_id = r.id AND c.status = 'active') AS active_contract_count
     FROM rooms r WHERE r.id = ?`, [id],
  );
  if (!rows[0]) throw new AppError(404, 'Không tìm thấy phòng');
  return rows[0];
};

const list = async (query) => {
  const status = query.status?.toString().trim();
  if (status && !ROOM_STATUSES.includes(status)) throw new AppError(400, 'Trạng thái lọc không hợp lệ');
  const keyword = query.keyword?.toString().trim();
  const conditions = [];
  const params = [];
  if (status) { conditions.push('r.status = ?'); params.push(status); }
  if (keyword) { conditions.push('r.room_number LIKE ?'); params.push(`%${keyword}%`); }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const [rows] = await pool.execute(
    `SELECT r.*,
      (SELECT COUNT(*) FROM tenants t WHERE t.room_id = r.id AND t.status = 'active') AS active_tenant_count
     FROM rooms r ${where} ORDER BY r.floor, r.room_number`, params,
  );
  return rows;
};

const create = async (body) => {
  const data = validate({ status: 'available', description: null, image_url: null, ...body });
  try {
    const [result] = await pool.execute(
      `INSERT INTO rooms (room_number, floor, area, price, deposit, status, description, image_url)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [data.room_number, data.floor, data.area, data.price, data.deposit, data.status, data.description, data.image_url],
    );
    return getById(result.insertId);
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') throw new AppError(409, 'Số phòng đã tồn tại');
    throw error;
  }
};

const update = async (value, body) => {
  const id = parseId(value);
  await getById(id);
  const data = validate(body, true);
  const fields = Object.keys(data);
  if (!fields.length) throw new AppError(400, 'Không có thông tin phòng cần cập nhật');
  if (data.status === 'available') {
    const current = await getById(id);
    if (current.active_tenant_count > 0 || current.active_contract_count > 0) {
      throw new AppError(409, 'Phòng đang có người thuê hoặc hợp đồng hoạt động nên không thể chuyển sang còn trống');
    }
  }
  try {
    await pool.execute(`UPDATE rooms SET ${fields.map((key) => `${key} = ?`).join(', ')} WHERE id = ?`, [...fields.map((key) => data[key]), id]);
    return getById(id);
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') throw new AppError(409, 'Số phòng đã tồn tại');
    throw error;
  }
};

const remove = async (value) => {
  const id = parseId(value);
  const room = await getById(id);
  const tables = ['tenants', 'contracts', 'utility_readings', 'invoices', 'maintenance_requests'];
  for (const table of tables) {
    const [rows] = await pool.execute(`SELECT COUNT(*) AS total FROM ${table} WHERE room_id = ?`, [id]);
    if (rows[0].total > 0) throw new AppError(409, `Phòng ${room.room_number} đã có dữ liệu liên quan. Hãy chuyển phòng sang trạng thái ngừng hoạt động thay vì xóa.`);
  }
  await pool.execute('DELETE FROM rooms WHERE id = ?', [id]);
};

const uploadImage = async (body) => {
  const mimeTypes = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };
  const extension = mimeTypes[body.mime_type];
  if (!extension || typeof body.data !== 'string' || !body.data) {
    throw new AppError(400, 'Ảnh phải có định dạng JPEG, PNG hoặc WebP');
  }
  let buffer;
  try {
    buffer = Buffer.from(body.data, 'base64');
  } catch (_) {
    throw new AppError(400, 'Dữ liệu ảnh không hợp lệ');
  }
  if (!buffer.length || buffer.length > 5 * 1024 * 1024) {
    throw new AppError(400, 'Kích thước ảnh phải từ 1 byte đến 5 MB');
  }
  const directory = path.join(__dirname, '..', '..', '..', 'uploads', 'rooms');
  await fs.mkdir(directory, { recursive: true });
  const fileName = `${Date.now()}-${crypto.randomUUID()}.${extension}`;
  await fs.writeFile(path.join(directory, fileName), buffer, { flag: 'wx' });
  return `/uploads/rooms/${fileName}`;
};

module.exports = { ROOM_STATUSES, list, getById, create, update, remove, uploadImage };
