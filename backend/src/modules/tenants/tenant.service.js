const { pool } = require('../../config/db');
const AppError = require('../../utils/app-error');

const parseId = (value, label = 'Mã người thuê') => {
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0) throw new AppError(400, `${label} không hợp lệ`);
  return id;
};
const optionalText = (value, max, label) => {
  const text = value?.toString().trim() || null;
  if (text && text.length > max) throw new AppError(400, `${label} tối đa ${max} ký tự`);
  return text;
};

const validate = (body, partial = false) => {
  const data = {};
  const has = (key) => !partial || Object.prototype.hasOwnProperty.call(body, key);
  if (has('full_name')) {
    const value = optionalText(body.full_name, 150, 'Họ tên');
    if (!value) throw new AppError(400, 'Họ tên là bắt buộc');
    data.full_name = value;
  }
  if (has('phone')) {
    const value = optionalText(body.phone, 20, 'Số điện thoại');
    if (!value) throw new AppError(400, 'Số điện thoại là bắt buộc');
    data.phone = value;
  }
  for (const [key, max, label] of [['email', 150, 'Email'], ['citizen_id', 30, 'CCCD'], ['hometown', 255, 'Quê quán'], ['address', 255, 'Địa chỉ'], ['citizen_front_image_url', 500, 'Ảnh CCCD mặt trước'], ['citizen_back_image_url', 500, 'Ảnh CCCD mặt sau']]) {
    if (has(key)) data[key] = optionalText(body[key], max, label);
  }
  if (has('date_of_birth')) {
    const value = body.date_of_birth?.toString().trim() || null;
    if (value && !/^\d{4}-\d{2}-\d{2}$/.test(value)) throw new AppError(400, 'Ngày sinh phải có định dạng YYYY-MM-DD');
    data.date_of_birth = value;
  }
  if (has('room_id')) data.room_id = body.room_id == null || body.room_id === '' ? null : parseId(body.room_id, 'Mã phòng');
  if (has('user_id')) data.user_id = body.user_id == null || body.user_id === '' ? null : parseId(body.user_id, 'Mã tài khoản');
  if (has('is_representative')) data.is_representative = Boolean(body.is_representative);
  if (has('status')) {
    if (!['active', 'left'].includes(body.status)) throw new AppError(400, 'Trạng thái người thuê không hợp lệ');
    data.status = body.status;
  }
  return data;
};

const getById = async (value, executor = pool) => {
  const id = parseId(value);
  const [rows] = await executor.execute(
    `SELECT t.*, r.room_number,
      (SELECT COUNT(*) FROM contracts c WHERE c.tenant_id=t.id AND c.status='active') AS active_contract_count
     FROM tenants t LEFT JOIN rooms r ON r.id=t.room_id WHERE t.id=?`, [id],
  );
  if (!rows[0]) throw new AppError(404, 'Không tìm thấy người thuê');
  return rows[0];
};

const list = async (query) => {
  const conditions = [];
  const params = [];
  if (query.status) {
    if (!['active', 'left'].includes(query.status)) throw new AppError(400, 'Trạng thái lọc không hợp lệ');
    conditions.push('t.status=?'); params.push(query.status);
  }
  if (query.room_id) { conditions.push('t.room_id=?'); params.push(parseId(query.room_id, 'Mã phòng')); }
  if (query.keyword) {
    const keyword = `%${query.keyword.toString().trim()}%`;
    conditions.push('(t.full_name LIKE ? OR t.phone LIKE ? OR t.email LIKE ? OR t.citizen_id LIKE ?)');
    params.push(keyword, keyword, keyword, keyword);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const [rows] = await pool.execute(
    `SELECT t.*, r.room_number FROM tenants t LEFT JOIN rooms r ON r.id=t.room_id ${where} ORDER BY t.created_at DESC`, params,
  );
  return rows;
};

const ensureRoomAssignable = async (roomId, connection) => {
  if (!roomId) return;
  const [rows] = await connection.execute('SELECT id, status FROM rooms WHERE id=? FOR UPDATE', [roomId]);
  if (!rows[0]) throw new AppError(404, 'Không tìm thấy phòng được chọn');
  if (['maintenance', 'inactive', 'deleted'].includes(rows[0].status)) throw new AppError(409, 'Không thể gán người thuê vào phòng đang bảo trì, ngừng hoạt động hoặc đã lưu lịch sử');
};

const syncRoom = async (roomId, connection) => {
  if (!roomId) return;
  const [counts] = await connection.execute(
    `SELECT
      (SELECT COUNT(*) FROM tenants WHERE room_id=? AND status='active') +
      (SELECT COUNT(*) FROM contracts WHERE room_id=? AND status='active') AS total`, [roomId, roomId],
  );
  if (counts[0].total > 0) await connection.execute("UPDATE rooms SET status='occupied' WHERE id=? AND status NOT IN ('maintenance','inactive','deleted')", [roomId]);
  else await connection.execute("UPDATE rooms SET status='available' WHERE id=? AND status='occupied'", [roomId]);
};

const create = async (body) => {
  const data = validate({ user_id: null, room_id: null, email: null, citizen_id: null, date_of_birth: null, hometown: null, address: null, citizen_front_image_url: null, citizen_back_image_url: null, is_representative: false, status: 'active', ...body });
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await ensureRoomAssignable(data.room_id, connection);
    const fields = Object.keys(data);
    const [result] = await connection.execute(`INSERT INTO tenants (${fields.join(',')}) VALUES (${fields.map(() => '?').join(',')})`, fields.map((key) => data[key]));
    await syncRoom(data.room_id, connection);
    await connection.commit();
    return getById(result.insertId);
  } catch (error) {
    await connection.rollback();
    if (error.code === 'ER_DUP_ENTRY') throw new AppError(409, 'CCCD hoặc tài khoản đã được gắn với người thuê khác');
    throw error;
  } finally { connection.release(); }
};

const update = async (value, body) => {
  const id = parseId(value);
  const data = validate(body, true);
  if (!Object.keys(data).length) throw new AppError(400, 'Không có thông tin cần cập nhật');
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const current = await getById(id, connection);
    if (Object.prototype.hasOwnProperty.call(data, 'room_id')) await ensureRoomAssignable(data.room_id, connection);
    const fields = Object.keys(data);
    await connection.execute(`UPDATE tenants SET ${fields.map((key) => `${key}=?`).join(',')} WHERE id=?`, [...fields.map((key) => data[key]), id]);
    await syncRoom(current.room_id, connection);
    await syncRoom(Object.prototype.hasOwnProperty.call(data, 'room_id') ? data.room_id : current.room_id, connection);
    await connection.commit();
    return getById(id);
  } catch (error) {
    await connection.rollback();
    if (error.code === 'ER_DUP_ENTRY') throw new AppError(409, 'CCCD hoặc tài khoản đã được gắn với người thuê khác');
    throw error;
  } finally { connection.release(); }
};

const remove = async (value) => {
  const id = parseId(value);
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const tenant = await getById(id, connection);
    if (tenant.active_contract_count > 0) throw new AppError(409, 'Hãy kết thúc hợp đồng đang hoạt động trước khi cho người thuê rời đi');
    await connection.execute("UPDATE tenants SET room_id=NULL, status='left', is_representative=FALSE WHERE id=?", [id]);
    await syncRoom(tenant.room_id, connection);
    await connection.commit();
  } catch (error) { await connection.rollback(); throw error; }
  finally { connection.release(); }
};

module.exports = { list, getById, create, update, remove, syncRoom };
