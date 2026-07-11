const mysql = require('mysql2');

const conn = mysql.createConnection({
    host: "localhost",
    port: 3306,
    user: "root",
    password: "123456",
    database: "quan_ly_tro"
});

conn.connect((err) => {
    if (err) {
        console.log("Loi ket noi MySQL (contract module):", err);
    } else {
        console.log("Contract module: Ket noi MySQL thanh cong");
    }
});

const getAllContracts = (callback) => {
  const sql = `
    SELECT c.*, r.room_number, t.full_name AS tenant_name, t.phone AS tenant_phone
    FROM contracts c
    JOIN rooms r ON c.room_id = r.id
    JOIN tenants t ON c.tenant_id = t.id
    ORDER BY c.created_at DESC
  `;
  conn.query(sql, callback);
};

const getContractById = (id, callback) => {
  const sql = `
    SELECT c.*, r.room_number, t.full_name AS tenant_name, t.phone AS tenant_phone
    FROM contracts c
    JOIN rooms r ON c.room_id = r.id
    JOIN tenants t ON c.tenant_id = t.id
    WHERE c.id = ?
  `;
  conn.query(sql, [id], callback);
};

const getContractsByTenant = (tenantId, callback) => {
  const sql = `SELECT * FROM contracts WHERE tenant_id = ? ORDER BY start_date DESC`;
  conn.query(sql, [tenantId], callback);
};

// Check phòng có hợp đồng active nào chưa (để chặn trùng)
const checkRoomHasActiveContract = (roomId, callback) => {
  const sql = `SELECT COUNT(*) AS total FROM contracts WHERE room_id = ? AND status = 'active'`;
  conn.query(sql, [roomId], callback);
};

// Tạo hợp đồng: insert contract + update room + update tenant (transaction)
const createContract = (data, callback) => {
  conn.beginTransaction((err) => {
    if (err) return callback(err);

    const insertSql = `
      INSERT INTO contracts
        (room_id, tenant_id, start_date, end_date, monthly_price, deposit_amount, status, note)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const params = [
      data.room_id,
      data.tenant_id,
      data.start_date,
      data.end_date,
      data.monthly_price,
      data.deposit_amount ?? 0,
      data.status ?? 'active',
      data.note ?? null
    ];

    conn.query(insertSql, params, (err, result) => {
      if (err) return conn.rollback(() => callback(err));

      const contractId = result.insertId;

      // Nếu tạo với status active thì mới đổi trạng thái phòng/tenant ngay
      if ((data.status ?? 'active') !== 'active') {
        return conn.commit((err) => {
          if (err) return conn.rollback(() => callback(err));
          callback(null, { insertId: contractId });
        });
      }

      const updateRoomSql = `UPDATE rooms SET status = 'occupied' WHERE id = ?`;
      conn.query(updateRoomSql, [data.room_id], (err) => {
        if (err) return conn.rollback(() => callback(err));

        const updateTenantSql = `UPDATE tenants SET room_id = ?, status = 'active' WHERE id = ?`;
        conn.query(updateTenantSql, [data.room_id, data.tenant_id], (err) => {
          if (err) return conn.rollback(() => callback(err));

          conn.commit((err) => {
            if (err) return conn.rollback(() => callback(err));
            callback(null, { insertId: contractId });
          });
        });
      });
    });
  });
};

// Gia hạn hợp đồng: chỉ đổi end_date
const extendContract = (id, newEndDate, callback) => {
  const sql = `UPDATE contracts SET end_date = ? WHERE id = ?`;
  conn.query(sql, [newEndDate, id], callback);
};

// Kết thúc hợp đồng: update contract + room + tenant (transaction)
const terminateContract = (id, callback) => {
  conn.beginTransaction((err) => {
    if (err) return callback(err);

    const getContractSql = `SELECT room_id, tenant_id FROM contracts WHERE id = ?`;
    conn.query(getContractSql, [id], (err, rows) => {
      if (err) return conn.rollback(() => callback(err));
      if (rows.length === 0) return conn.rollback(() => callback(null, { notFound: true }));

      const { room_id, tenant_id } = rows[0];

      const updateContractSql = `
        UPDATE contracts SET status = 'terminated', terminated_at = CURDATE() WHERE id = ?
      `;
      conn.query(updateContractSql, [id], (err) => {
        if (err) return conn.rollback(() => callback(err));

        const updateRoomSql = `UPDATE rooms SET status = 'available' WHERE id = ?`;
        conn.query(updateRoomSql, [room_id], (err) => {
          if (err) return conn.rollback(() => callback(err));

          const updateTenantSql = `UPDATE tenants SET room_id = NULL, status = 'left' WHERE id = ?`;
          conn.query(updateTenantSql, [tenant_id], (err) => {
            if (err) return conn.rollback(() => callback(err));

            conn.commit((err) => {
              if (err) return conn.rollback(() => callback(err));
              callback(null, { success: true });
            });
          });
        });
      });
    });
  });
};

module.exports = {
  getAllContracts,
  getContractById,
  getContractsByTenant,
  checkRoomHasActiveContract,
  createContract,
  extendContract,
  terminateContract
};