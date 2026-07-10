const { conn } = require('../../../server');

// Lấy danh sách tất cả tenant
const getAllTenants = (callback) => {
  const sql = `
    SELECT t.*, r.room_number
    FROM tenants t
    LEFT JOIN rooms r ON t.room_id = r.id
    ORDER BY t.created_at DESC
  `;
  conn.query(sql, callback);
};

// Lấy chi tiết 1 tenant theo id
const getTenantById = (id, callback) => {
  const sql = `
    SELECT t.*, r.room_number
    FROM tenants t
    LEFT JOIN rooms r ON t.room_id = r.id
    WHERE t.id = ?
  `;
  conn.query(sql, [id], callback);
};

// Lấy danh sách tenant theo phòng
const getTenantsByRoom = (roomId, callback) => {
  const sql = `SELECT * FROM tenants WHERE room_id = ? ORDER BY created_at DESC`;
  conn.query(sql, [roomId], callback);
};

// Tạo tenant mới
const createTenant = (data, callback) => {
  const sql = `
    INSERT INTO tenants
      (user_id, room_id, full_name, phone, email, citizen_id, date_of_birth,
       hometown, address, citizen_front_image_url, citizen_back_image_url,
       is_representative, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;
  const params = [
    data.user_id ?? null,
    data.room_id ?? null,
    data.full_name,
    data.phone,
    data.email ?? null,
    data.citizen_id ?? null,
    data.date_of_birth ?? null,
    data.hometown ?? null,
    data.address ?? null,
    data.citizen_front_image_url ?? null,
    data.citizen_back_image_url ?? null,
    data.is_representative ?? false,
    data.status ?? 'active'
  ];
  conn.query(sql, params, callback);
};

// Cập nhật tenant
const updateTenant = (id, data, callback) => {
  const sql = `
    UPDATE tenants SET
      user_id = ?,
      room_id = ?,
      full_name = ?,
      phone = ?,
      email = ?,
      citizen_id = ?,
      date_of_birth = ?,
      hometown = ?,
      address = ?,
      citizen_front_image_url = ?,
      citizen_back_image_url = ?,
      is_representative = ?,
      status = ?
    WHERE id = ?
  `;
  const params = [
    data.user_id ?? null,
    data.room_id ?? null,
    data.full_name,
    data.phone,
    data.email ?? null,
    data.citizen_id ?? null,
    data.date_of_birth ?? null,
    data.hometown ?? null,
    data.address ?? null,
    data.citizen_front_image_url ?? null,
    data.citizen_back_image_url ?? null,
    data.is_representative ?? false,
    data.status ?? 'active',
    id
  ];
  conn.query(sql, params, callback);
};

// Xóa tenant
const deleteTenant = (id, callback) => {
  const sql = `DELETE FROM tenants WHERE id = ?`;
  conn.query(sql, [id], callback);
};

module.exports = {
  getAllTenants,
  getTenantById,
  getTenantsByRoom,
  createTenant,
  updateTenant,
  deleteTenant
};