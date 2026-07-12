const dashboardService = require('./dashboard.service');

function success(res, data) {
    return res.json({
        success: true,
        message: 'Thành công',
        data,
    });
}

async function getSummary(req, res) {
    try {
        const data = await dashboardService.getSummary(
            req.query.month,
            req.query.year
        );

        return success(res, data);
    } catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message || 'Lỗi server',
        });
    }
}

async function getRevenueOverview(req, res) {
    try {
        const data = await dashboardService.getRevenueOverview(req.query.year);

        return success(res, data);
    } catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message || 'Lỗi server',
        });
    }
}

async function getRecentMaintenance(req, res) {
    try {
        const data = await dashboardService.getRecentMaintenance(req.query.limit);

        return success(res, data);
    } catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message || 'Lỗi server',
        });
    }
}

module.exports = {
    getSummary,
    getRevenueOverview,
    getRecentMaintenance,
};