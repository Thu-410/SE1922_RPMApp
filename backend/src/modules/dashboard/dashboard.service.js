const { query } = require('../../config/db');

async function getSummary(month, year) {
    const now = new Date();
    const targetMonth = Number(month || now.getMonth() + 1);
    const targetYear = Number(year || now.getFullYear());

    const [[roomStats]] = await query(
        `SELECT
            COUNT(*) AS total_rooms,
            COALESCE(SUM(CASE WHEN status = 'occupied' THEN 1 ELSE 0 END), 0) AS occupied_rooms,
            COALESCE(SUM(CASE WHEN status = 'available' THEN 1 ELSE 0 END), 0) AS available_rooms,
            COALESCE(SUM(CASE WHEN status = 'maintenance' THEN 1 ELSE 0 END), 0) AS maintenance_rooms,
            COALESCE(SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END), 0) AS inactive_rooms
        FROM rooms`
    );

    const [[invoiceStats]] = await query(
        `SELECT
            COUNT(*) AS total_invoices,
            COALESCE(SUM(CASE WHEN status = 'unpaid' THEN 1 ELSE 0 END), 0) AS unpaid_invoices,
            COALESCE(SUM(CASE WHEN status = 'overdue' THEN 1 ELSE 0 END), 0) AS overdue_invoices,
            COALESCE(SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END), 0) AS paid_invoices,
            COALESCE(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) AS total_paid_invoice_amount,
            COALESCE(SUM(CASE WHEN status IN ('unpaid', 'overdue') THEN total_amount ELSE 0 END), 0) AS total_debt_amount,
            COALESCE(SUM(CASE WHEN status = 'paid' AND month = ? AND year = ? THEN total_amount ELSE 0 END), 0) AS current_month_revenue
        FROM invoices`,
        [targetMonth, targetYear]
    );

    const [[maintenanceStats]] = await query(
        `SELECT
            COUNT(*) AS total_maintenance_requests,
            COALESCE(SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END), 0) AS pending_requests,
            COALESCE(SUM(CASE WHEN status = 'processing' THEN 1 ELSE 0 END), 0) AS processing_requests,
            COALESCE(SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END), 0) AS completed_requests,
            COALESCE(SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END), 0) AS cancelled_requests
        FROM maintenance_requests`
    );

    return {
        month: targetMonth,
        year: targetYear,

        total_rooms: Number(roomStats.total_rooms || 0),
        occupied_rooms: Number(roomStats.occupied_rooms || 0),
        available_rooms: Number(roomStats.available_rooms || 0),
        maintenance_rooms: Number(roomStats.maintenance_rooms || 0),
        inactive_rooms: Number(roomStats.inactive_rooms || 0),

        total_invoices: Number(invoiceStats.total_invoices || 0),
        unpaid_invoices: Number(invoiceStats.unpaid_invoices || 0),
        overdue_invoices: Number(invoiceStats.overdue_invoices || 0),
        paid_invoices: Number(invoiceStats.paid_invoices || 0),
        total_paid_invoice_amount: Number(invoiceStats.total_paid_invoice_amount || 0),
        total_debt_amount: Number(invoiceStats.total_debt_amount || 0),
        current_month_revenue: Number(invoiceStats.current_month_revenue || 0),

        total_maintenance_requests: Number(maintenanceStats.total_maintenance_requests || 0),
        pending_requests: Number(maintenanceStats.pending_requests || 0),
        processing_requests: Number(maintenanceStats.processing_requests || 0),
        completed_requests: Number(maintenanceStats.completed_requests || 0),
        cancelled_requests: Number(maintenanceStats.cancelled_requests || 0),
    };
}

async function getRevenueOverview(year) {
    const targetYear = Number(year || new Date().getFullYear());

    const [rows] = await query(
        `SELECT
            month,
            COALESCE(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) AS revenue,
            COALESCE(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) AS total_revenue,
            COALESCE(SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END), 0) AS total_paid_invoices
        FROM invoices
        WHERE year = ?
        GROUP BY month
        ORDER BY month`,
        [targetYear]
    );

    return Array.from({ length: 12 }, (_, index) => {
        const month = index + 1;
        const found = rows.find((item) => Number(item.month) === month);

        return {
            month,
            year: targetYear,
            revenue: Number(found?.revenue || 0),
            total_revenue: Number(found?.total_revenue || 0),
            total_paid_invoices: Number(found?.total_paid_invoices || 0),
        };
    });
}

async function getRecentMaintenance(limit = 5) {
    const safeLimit = Math.min(Math.max(Number(limit || 5), 1), 20);

    const [rows] = await query(
        `SELECT
            mr.id,
            mr.room_id,
            r.room_number,
            mr.tenant_id,
            t.full_name AS tenant_name,
            t.phone AS tenant_phone,
            t.email AS tenant_email,
            mr.title,
            mr.description,
            mr.image_url,
            mr.status,
            mr.manager_note,
            mr.created_at,
            mr.updated_at
        FROM maintenance_requests mr
        LEFT JOIN rooms r ON r.id = mr.room_id
        LEFT JOIN tenants t ON t.id = mr.tenant_id
        ORDER BY mr.created_at DESC
        OFFSET 0 ROWS FETCH NEXT ? ROWS ONLY`,
        [safeLimit]
    );

    return rows;
}

module.exports = {
    getSummary,
    getRevenueOverview,
    getRecentMaintenance,
};