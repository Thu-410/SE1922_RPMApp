const { pool } = require('../../config/db');
const AppError = require('../../utils/app-error');

const STATUSES = ['pending', 'processing', 'completed', 'cancelled'];
const ISSUE_TYPES = ['electric', 'water', 'internet', 'furniture', 'lock', 'cleaning', 'other'];

const positiveId = (value, field = 'id') => {
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0) throw new AppError(400, `${field} không hợp lệ`);
  return id;
};

const tenantForUser = async (userId, connection = pool) => {
  const [rows] = await connection.execute(
    `SELECT id, room_id FROM tenants
     WHERE user_id = ? AND status = 'active' LIMIT 1`,
    [userId],
  );
  if (!rows.length || !rows[0].room_id) throw new AppError(409, 'Tài khoản chưa được gán phòng đang thuê');
  return rows[0];
};

const ownershipClause = (user, params) => {
  if (user.role !== 'tenant') return '';
  params.push(user.id);
  return ' AND t.user_id = ?';
};

const list = async (query, user) => {
  const page = Math.max(Number.parseInt(query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(Number.parseInt(query.limit, 10) || 20, 1), 100);
  const conditions = [];
  const params = [];
  if (user.role === 'tenant') {
    conditions.push('t.user_id = ?');
    params.push(user.id);
  }
  if (query.status) {
    if (!STATUSES.includes(query.status)) throw new AppError(400, 'Trạng thái không hợp lệ');
    conditions.push('mr.status = ?');
    params.push(query.status);
  }
  if (query.keyword) {
    conditions.push('(mr.title LIKE ? OR mr.description LIKE ? OR r.room_number LIKE ? OR t.full_name LIKE ?)');
    const keyword = `%${query.keyword}%`;
    params.push(keyword, keyword, keyword, keyword);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const [counts] = await pool.execute(
    `SELECT COUNT(*) AS total FROM maintenance_requests mr
     JOIN tenants t ON t.id = mr.tenant_id JOIN rooms r ON r.id = mr.room_id ${where}`,
    params,
  );
  const [rows] = await pool.execute(
    `SELECT mr.*, r.room_number, t.full_name AS tenant_name, t.phone AS tenant_phone,
            assignee.full_name AS assigned_staff_name
     FROM maintenance_requests mr
     JOIN rooms r ON r.id = mr.room_id
     JOIN tenants t ON t.id = mr.tenant_id
     LEFT JOIN users assignee ON assignee.id = mr.assigned_staff_id
     ${where}
     ORDER BY mr.created_at DESC, mr.id DESC LIMIT ? OFFSET ?`,
    [...params, limit, (page - 1) * limit],
  );
  const total = Number(counts[0].total);
  return { rows, meta: { page, limit, total, totalPages: Math.ceil(total / limit) } };
};

const getById = async (id, user, connection = pool) => {
  const params = [positiveId(id)];
  const owner = ownershipClause(user, params);
  const [rows] = await connection.execute(
    `SELECT mr.*, r.room_number, t.full_name AS tenant_name, t.phone AS tenant_phone,
            t.email AS tenant_email, assignee.full_name AS assigned_staff_name
     FROM maintenance_requests mr
     JOIN rooms r ON r.id = mr.room_id
     JOIN tenants t ON t.id = mr.tenant_id
     LEFT JOIN users assignee ON assignee.id = mr.assigned_staff_id
     WHERE mr.id = ?${owner} LIMIT 1`,
    params,
  );
  if (!rows.length) throw new AppError(404, 'Không tìm thấy yêu cầu sửa chữa');
  return rows[0];
};

const create = async (payload, user) => {
  const title = String(payload.title || '').trim();
  const description = String(payload.description || '').trim();
  const issueType = payload.issue_type || 'other';
  if (!title || !description) throw new AppError(400, 'Tiêu đề và mô tả là bắt buộc');
  if (!ISSUE_TYPES.includes(issueType)) throw new AppError(400, 'Loại sự cố không hợp lệ');

  let tenantId;
  let roomId;
  if (user.role === 'tenant') {
    const tenant = await tenantForUser(user.id);
    tenantId = tenant.id;
    roomId = tenant.room_id;
  } else {
    tenantId = positiveId(payload.tenant_id, 'tenant_id');
    roomId = positiveId(payload.room_id, 'room_id');
  }
  const [result] = await pool.execute(
    `INSERT INTO maintenance_requests
     (room_id, tenant_id, title, issue_type, description, image_url, status)
     VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
    [roomId, tenantId, title, issueType, description, payload.image_url || null],
  );
  return getById(result.insertId, user);
};

const updateStatus = async (id, payload, user) => {
  const requestId = positiveId(id);
  if (!STATUSES.includes(payload.status)) throw new AppError(400, 'Trạng thái không hợp lệ');
  let assignedStaffId = payload.assigned_staff_id ?? null;
  if (assignedStaffId != null) assignedStaffId = positiveId(assignedStaffId, 'assigned_staff_id');
  if (user.role === 'staff' && assignedStaffId == null) assignedStaffId = user.id;
  const [result] = await pool.execute(
    `UPDATE maintenance_requests
     SET status = ?, manager_note = COALESCE(?, manager_note),
         assigned_staff_id = COALESCE(?, assigned_staff_id),
         completed_at = CASE WHEN ? = 'completed' THEN CURRENT_TIMESTAMP ELSE NULL END
     WHERE id = ?`,
    [payload.status, payload.manager_note || null, assignedStaffId, payload.status, requestId],
  );
  if (!result.affectedRows) throw new AppError(404, 'Không tìm thấy yêu cầu sửa chữa');
  return getById(requestId, user);
};

module.exports = { list, getById, create, updateStatus };
