const { pool } = require('../../config/db');
const AppError = require('../../utils/app-error');

const normalizeYear = (value) => {
  const year = Number(value || new Date().getFullYear());
  if (!Number.isInteger(year) || year < 2020 || year > 2100) throw new AppError(400, 'Năm không hợp lệ');
  return year;
};

const revenue = async (query) => {
  const year = normalizeYear(query.year);
  const month = query.month == null || query.month === '' ? null : Number(query.month);
  if (month != null && (!Number.isInteger(month) || month < 1 || month > 12)) throw new AppError(400, 'Tháng không hợp lệ');
  const params = [year];
  let monthClause = '';
  if (month != null) {
    monthClause = ' AND MONTH(p.payment_date) = ?';
    params.push(month);
  }
  const [summaryRows] = await pool.execute(
    `SELECT COALESCE(SUM(p.amount), 0) AS total_revenue, COUNT(*) AS payment_count
     FROM payments p WHERE YEAR(p.payment_date) = ?${monthClause}`,
    params,
  );
  const [rows] = await pool.execute(
    `SELECT MONTH(payment_date) AS month, YEAR(payment_date) AS year,
            COALESCE(SUM(amount), 0) AS total_revenue, COUNT(*) AS total_paid_invoices
     FROM payments WHERE YEAR(payment_date) = ?
     GROUP BY MONTH(payment_date), YEAR(payment_date) ORDER BY month`,
    [year],
  );
  const byMonth = Array.from({ length: 12 }, (_, index) => {
    const found = rows.find((row) => Number(row.month) === index + 1);
    return { month: index + 1, year, revenue: Number(found?.total_revenue || 0), total_revenue: Number(found?.total_revenue || 0), total_paid_invoices: Number(found?.total_paid_invoices || 0) };
  });
  return { month, year, total_revenue: Number(summaryRows[0].total_revenue), payment_count: Number(summaryRows[0].payment_count), rows: byMonth };
};

const occupancy = async () => {
  const [summaryRows] = await pool.execute(
    `SELECT COUNT(*) AS total_rooms,
      SUM(status = 'occupied') AS occupied_rooms, SUM(status = 'available') AS available_rooms,
      SUM(status = 'maintenance') AS maintenance_rooms, SUM(status = 'inactive') AS inactive_rooms
     FROM rooms`,
  );
  const [rooms] = await pool.execute(
    `SELECT r.id, r.room_number, r.floor, r.area, r.price, r.status,
            GROUP_CONCAT(CASE WHEN t.status = 'active' THEN t.full_name END SEPARATOR ', ') AS tenant_name,
            GROUP_CONCAT(CASE WHEN t.status = 'active' THEN t.phone END SEPARATOR ', ') AS tenant_phone
     FROM rooms r LEFT JOIN tenants t ON t.room_id = r.id
     GROUP BY r.id ORDER BY r.floor, r.room_number`,
  );
  const s = summaryRows[0];
  return { summary: { total_rooms: Number(s.total_rooms || 0), occupied_rooms: Number(s.occupied_rooms || 0), available_rooms: Number(s.available_rooms || 0), maintenance_rooms: Number(s.maintenance_rooms || 0), inactive_rooms: Number(s.inactive_rooms || 0), occupancy_rate: s.total_rooms ? Number((Number(s.occupied_rooms || 0) * 100 / Number(s.total_rooms)).toFixed(2)) : 0 }, rooms };
};

const debts = async (query) => {
  const limit = Math.min(Math.max(Number.parseInt(query.limit, 10) || 50, 1), 100);
  const [summaryRows] = await pool.execute(
    `SELECT COUNT(*) AS debt_invoice_count, COALESCE(SUM(total_amount), 0) AS total_debt_amount
     FROM invoices WHERE status IN ('unpaid', 'overdue')`,
  );
  const [rows] = await pool.execute(
    `SELECT i.id AS invoice_id, i.month, i.year, i.total_amount, i.status, i.due_date,
            r.room_number, t.full_name AS tenant_name, t.phone AS tenant_phone
     FROM invoices i JOIN rooms r ON r.id = i.room_id JOIN tenants t ON t.id = i.tenant_id
     WHERE i.status IN ('unpaid', 'overdue') ORDER BY i.due_date, i.total_amount DESC LIMIT ?`,
    [limit],
  );
  return { summary: { debt_invoice_count: Number(summaryRows[0].debt_invoice_count), total_debt_amount: Number(summaryRows[0].total_debt_amount) }, rows };
};

module.exports = { revenue, occupancy, debts };
