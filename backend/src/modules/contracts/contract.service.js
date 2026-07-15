const { pool } = require('../../config/db');
const AppError = require('../../utils/app-error');
const { syncRoom } = require('../tenants/tenant.service');

const parseId = (value, label = 'Mã hợp đồng') => {
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0) throw new AppError(400, `${label} không hợp lệ`);
  return id;
};
const date = (value, label) => {
  const result = value?.toString().trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(result || '')) throw new AppError(400, `${label} phải có định dạng YYYY-MM-DD`);
  return result;
};

const getById = async (value, executor = pool) => {
  const id = parseId(value);
  const [rows] = await executor.execute(
    `SELECT c.*, r.room_number, t.full_name AS tenant_name, t.phone AS tenant_phone
     FROM contracts c JOIN rooms r ON r.id=c.room_id JOIN tenants t ON t.id=c.tenant_id WHERE c.id=?`, [id],
  );
  if (!rows[0]) throw new AppError(404, 'Không tìm thấy hợp đồng');
  return rows[0];
};

const list = async (query) => {
  const conditions = [];
  const params = [];
  if (query.status) {
    if (!['pending', 'active', 'expired', 'terminated'].includes(query.status)) throw new AppError(400, 'Trạng thái lọc không hợp lệ');
    conditions.push('c.status=?'); params.push(query.status);
  }
  if (query.tenant_id) { conditions.push('c.tenant_id=?'); params.push(parseId(query.tenant_id, 'Mã người thuê')); }
  if (query.room_id) { conditions.push('c.room_id=?'); params.push(parseId(query.room_id, 'Mã phòng')); }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const [rows] = await pool.execute(
    `SELECT c.*, r.room_number, t.full_name AS tenant_name, t.phone AS tenant_phone
     FROM contracts c JOIN rooms r ON r.id=c.room_id JOIN tenants t ON t.id=c.tenant_id ${where} ORDER BY c.created_at DESC`, params,
  );
  return rows;
};

const create = async (body) => {
  const roomId = parseId(body.room_id, 'Mã phòng');
  const tenantId = parseId(body.tenant_id, 'Mã người thuê');
  const startDate = date(body.start_date, 'Ngày bắt đầu');
  const endDate = date(body.end_date, 'Ngày kết thúc');
  if (endDate <= startDate) throw new AppError(400, 'Ngày kết thúc phải sau ngày bắt đầu');
  const monthlyPrice = Number(body.monthly_price);
  const depositAmount = Number(body.deposit_amount || 0);
  if (!Number.isFinite(monthlyPrice) || monthlyPrice < 0 || !Number.isFinite(depositAmount) || depositAmount < 0) throw new AppError(400, 'Giá thuê và tiền cọc phải là số không âm');
  const status = body.status || 'active';
  if (!['pending', 'active'].includes(status)) throw new AppError(400, 'Hợp đồng mới chỉ có thể ở trạng thái chờ hoặc hoạt động');
  const note = body.note?.toString().trim() || null;
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [[room]] = await connection.execute('SELECT id,status FROM rooms WHERE id=? FOR UPDATE', [roomId]);
    const [[tenant]] = await connection.execute('SELECT id,status FROM tenants WHERE id=? FOR UPDATE', [tenantId]);
    if (!room) throw new AppError(404, 'Không tìm thấy phòng');
    if (!tenant) throw new AppError(404, 'Không tìm thấy người thuê');
    if (['maintenance', 'inactive'].includes(room.status)) throw new AppError(409, 'Không thể tạo hợp đồng cho phòng đang bảo trì hoặc ngừng hoạt động');
    if (status === 'active') {
      const [[roomConflict]] = await connection.execute("SELECT COUNT(*) total FROM contracts WHERE room_id=? AND status='active'", [roomId]);
      const [[tenantConflict]] = await connection.execute("SELECT COUNT(*) total FROM contracts WHERE tenant_id=? AND status='active'", [tenantId]);
      if (roomConflict.total > 0) throw new AppError(409, 'Phòng đã có hợp đồng đang hoạt động');
      if (tenantConflict.total > 0) throw new AppError(409, 'Người thuê đã có hợp đồng đang hoạt động');
    }
    const [result] = await connection.execute(
      `INSERT INTO contracts (room_id,tenant_id,start_date,end_date,monthly_price,deposit_amount,status,note)
       VALUES (?,?,?,?,?,?,?,?)`, [roomId, tenantId, startDate, endDate, monthlyPrice, depositAmount, status, note],
    );
    if (status === 'active') {
      await connection.execute("UPDATE tenants SET room_id=?,status='active' WHERE id=?", [roomId, tenantId]);
      await syncRoom(roomId, connection);
    }
    await connection.commit();
    return getById(result.insertId);
  } catch (error) { await connection.rollback(); throw error; }
  finally { connection.release(); }
};

const extend = async (value, body) => {
  const id = parseId(value);
  const newEndDate = date(body.new_end_date || body.end_date, 'Ngày kết thúc mới');
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const contract = await getById(id, connection);
    if (contract.status !== 'active') throw new AppError(409, 'Chỉ có thể gia hạn hợp đồng đang hoạt động');
    if (newEndDate <= contract.end_date) throw new AppError(400, 'Ngày kết thúc mới phải sau ngày kết thúc hiện tại');
    await connection.execute('UPDATE contracts SET end_date=? WHERE id=?', [newEndDate, id]);
    await connection.commit();
    return getById(id);
  } catch (error) { await connection.rollback(); throw error; }
  finally { connection.release(); }
};

const terminate = async (value) => {
  const id = parseId(value);
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const contract = await getById(id, connection);
    if (!['active', 'pending'].includes(contract.status)) throw new AppError(409, 'Hợp đồng đã kết thúc hoặc hết hạn');
    await connection.execute("UPDATE contracts SET status='terminated',terminated_at=CURDATE() WHERE id=?", [id]);
    if (contract.status === 'active') {
      const [[remaining]] = await connection.execute("SELECT COUNT(*) total FROM contracts WHERE tenant_id=? AND status='active' AND id<>?", [contract.tenant_id, id]);
      if (remaining.total === 0) await connection.execute("UPDATE tenants SET room_id=NULL,status='left',is_representative=FALSE WHERE id=?", [contract.tenant_id]);
      await syncRoom(contract.room_id, connection);
    }
    await connection.commit();
    return getById(id);
  } catch (error) { await connection.rollback(); throw error; }
  finally { connection.release(); }
};

module.exports = { list, getById, create, extend, terminate };
