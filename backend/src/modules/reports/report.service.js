const { query } = require('../../config/db');

async function getRevenueReport(month, year) {
    const now = new Date();
    const targetMonth = month ? Number(month) : null;
    const targetYear = Number(year || now.getFullYear());

    const params = [targetYear];
    let where = 'WHERE year = ?';

    if (targetMonth) {
        where += ' AND month = ?';
        params.push(targetMonth);
    }

    const [[summary]] = await query(
        `SELECT
            COALESCE(SUM(total_amount), 0) AS expected_revenue,
            COALESCE(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) AS paid_revenue,
            COALESCE(SUM(CASE WHEN status IN ('unpaid', 'overdue') THEN total_amount ELSE 0 END), 0) AS unpaid_revenue,
            COUNT(*) AS invoice_count,
            COALESCE(SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END), 0) AS paid_count,
            COALESCE(SUM(CASE WHEN status IN ('unpaid', 'overdue') THEN 1 ELSE 0 END), 0) AS unpaid_count
        FROM invoices
        ${where}`,
        params
    );

    const [rows] = await query(
        `SELECT
            month,
            ? AS year,
            COALESCE(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) AS revenue,
            COALESCE(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) AS total_revenue,
            COALESCE(SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END), 0) AS total_paid_invoices
        FROM invoices
        WHERE year = ?
        GROUP BY month
        ORDER BY month`,
        [targetYear, targetYear]
    );

    return {
        month: targetMonth,
        year: targetYear,
        total_revenue: Number(summary.paid_revenue || 0),
        summary: {
            expected_revenue: Number(summary.expected_revenue || 0),
            paid_revenue: Number(summary.paid_revenue || 0),
            unpaid_revenue: Number(summary.unpaid_revenue || 0),
            invoice_count: Number(summary.invoice_count || 0),
            paid_count: Number(summary.paid_count || 0),
            unpaid_count: Number(summary.unpaid_count || 0),
        },
        rows: rows.map((item) => ({
            month: Number(item.month || 0),
            year: targetYear,
            revenue: Number(item.revenue || 0),
            total_revenue: Number(item.total_revenue || 0),
            total_paid_invoices: Number(item.total_paid_invoices || 0),
        })),
    };
}

async function getOccupancyReport() {
    const [[summary]] = await query(
        `SELECT
            COUNT(*) AS total_rooms,
            COALESCE(SUM(CASE WHEN status = 'occupied' THEN 1 ELSE 0 END), 0) AS occupied_rooms,
            COALESCE(SUM(CASE WHEN status = 'available' THEN 1 ELSE 0 END), 0) AS available_rooms,
            COALESCE(SUM(CASE WHEN status = 'maintenance' THEN 1 ELSE 0 END), 0) AS maintenance_rooms,
            COALESCE(SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END), 0) AS inactive_rooms
        FROM rooms`
    );

    const [rooms] = await query(
        `SELECT
            r.id,
            r.room_number,
            r.floor,
            r.area,
            r.price,
            r.status,
            t.full_name AS tenant_name,
            t.phone AS tenant_phone
        FROM rooms r
        LEFT JOIN tenants t ON t.room_id = r.id AND t.status = 'active'
        ORDER BY r.floor ASC, r.room_number ASC`
    );

    return {
        summary: {
            total_rooms: Number(summary.total_rooms || 0),
            occupied_rooms: Number(summary.occupied_rooms || 0),
            available_rooms: Number(summary.available_rooms || 0),
            maintenance_rooms: Number(summary.maintenance_rooms || 0),
            inactive_rooms: Number(summary.inactive_rooms || 0),
            occupancy_rate: summary.total_rooms
                ? Number((((summary.occupied_rooms || 0) / summary.total_rooms) * 100).toFixed(2))
                : 0,
        },
        rooms,
    };
}

async function getDebtReport(limit = 50) {
    const safeLimit = Math.min(Math.max(Number(limit || 50), 1), 100);

    const [[summary]] = await query(
        `SELECT
            COUNT(*) AS debt_invoice_count,
            COALESCE(SUM(total_amount), 0) AS total_debt_amount
        FROM invoices
        WHERE status IN ('unpaid', 'overdue')`
    );

    const [rows] = await query(
        `SELECT
            i.id AS invoice_id,
            i.month,
            i.year,
            i.total_amount,
            i.status,
            i.due_date,
            r.room_number,
            t.full_name AS tenant_name,
            t.phone AS tenant_phone
        FROM invoices i
        LEFT JOIN rooms r ON r.id = i.room_id
        LEFT JOIN tenants t ON t.id = i.tenant_id
        WHERE i.status IN ('unpaid', 'overdue')
        ORDER BY i.due_date ASC, i.total_amount DESC
        OFFSET 0 ROWS FETCH NEXT ? ROWS ONLY`,
        [safeLimit]
    );

    return {
        summary: {
            debt_invoice_count: Number(summary.debt_invoice_count || 0),
            total_debt_amount: Number(summary.total_debt_amount || 0),
        },
        rows: rows.map((item) => ({
            invoice_id: item.invoice_id,
            month: Number(item.month || 0),
            year: Number(item.year || 0),
            total_amount: Number(item.total_amount || 0),
            status: item.status,
            due_date: item.due_date,
            room_number: item.room_number,
            tenant_name: item.tenant_name,
            tenant_phone: item.tenant_phone,
        })),
    };
}

module.exports = {
    getRevenueReport,
    getOccupancyReport,
    getDebtReport,
};