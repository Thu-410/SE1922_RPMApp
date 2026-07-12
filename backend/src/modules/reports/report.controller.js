const reportService = require('./report.service');

function success(res, data) {
    return res.json({ success: true, message: 'Thành công', data });
}

async function getRevenueReport(req, res) {
    try {
        const data = await reportService.getRevenueReport(req.query.month, req.query.year);
        return success(res, data);
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message || 'Lỗi server' });
    }
}

async function getOccupancyReport(req, res) {
    try {
        const data = await reportService.getOccupancyReport();
        return success(res, data);
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message || 'Lỗi server' });
    }
}

async function getDebtReport(req, res) {
    try {
        const data = await reportService.getDebtReport(req.query.limit);
        return success(res, data);
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message || 'Lỗi server' });
    }
}

module.exports = {
    getRevenueReport,
    getOccupancyReport,
    getDebtReport,
};
