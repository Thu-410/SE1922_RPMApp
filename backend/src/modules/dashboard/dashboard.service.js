const { pool } = require('../../config/db');
const reportService = require('../reports/report.service');

const summary = async (query) => {
  const month = Number(query.month || new Date().getMonth() + 1);
  const year = Number(query.year || new Date().getFullYear());
  const [[roomRows], [invoiceRows], [maintenanceRows], [revenueRows]] = await Promise.all([
    pool.execute(`SELECT COUNT(*) AS total_rooms, SUM(status='occupied') AS occupied_rooms, SUM(status='available') AS available_rooms, SUM(status='maintenance') AS maintenance_rooms, SUM(status='inactive') AS inactive_rooms FROM rooms`),
    pool.execute(`SELECT COUNT(*) AS total_invoices, SUM(status='unpaid') AS unpaid_invoices, SUM(status='overdue') AS overdue_invoices, SUM(status='paid') AS paid_invoices, COALESCE(SUM(CASE WHEN status IN ('unpaid','overdue') THEN total_amount ELSE 0 END),0) AS total_debt_amount FROM invoices`),
    pool.execute(`SELECT COUNT(*) AS total_maintenance_requests, SUM(status='pending') AS pending_requests, SUM(status='processing') AS processing_requests, SUM(status='completed') AS completed_requests, SUM(status='cancelled') AS cancelled_requests FROM maintenance_requests`),
    pool.execute(`SELECT COALESCE(SUM(amount),0) AS current_month_revenue FROM payments WHERE MONTH(payment_date)=? AND YEAR(payment_date)=?`, [month, year]),
  ]);
  const values = { month, year, ...roomRows[0], ...invoiceRows[0], ...maintenanceRows[0], ...revenueRows[0] };
  return Object.fromEntries(Object.entries(values).map(([key, value]) => [key, typeof value === 'number' || typeof value === 'string' && !Number.isNaN(Number(value)) ? Number(value) : value]));
};

const revenueOverview = (query) => reportService.revenue({ year: query.year }).then((data) => data.rows);
const recentMaintenance = async (query) => {
  const limit = Math.min(Math.max(Number.parseInt(query.limit, 10) || 5, 1), 20);
  const [rows] = await pool.execute(
    `SELECT mr.*, r.room_number, t.full_name AS tenant_name, t.phone AS tenant_phone
     FROM maintenance_requests mr JOIN rooms r ON r.id=mr.room_id JOIN tenants t ON t.id=mr.tenant_id
     ORDER BY mr.created_at DESC LIMIT ?`, [limit],
  );
  return rows;
};

module.exports = { summary, revenueOverview, recentMaintenance };
