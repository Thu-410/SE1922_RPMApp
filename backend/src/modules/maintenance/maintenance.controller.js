const maintenanceService = require('./maintenance.service');

function success(res, data, message = 'Thành công') {
    return res.json({ success: true, message, data });
}

function error(res, err) {
    const status = err.statusCode || 500;
    return res.status(status).json({ success: false, message: err.message || 'Lỗi server' });
}

async function getAll(req, res) {
    try {
        const result = await maintenanceService.getAll(req.query, req.user);
        return success(res, result);
    } catch (err) {
        return error(res, err);
    }
}

async function getById(req, res) {
    try {
        const result = await maintenanceService.getById(req.params.id, req.user);
        if (result === 'FORBIDDEN') {
            return res.status(403).json({ success: false, message: 'Bạn không được xem yêu cầu này' });
        }
        if (!result) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy yêu cầu sửa chữa' });
        }
        return success(res, result);
    } catch (err) {
        return error(res, err);
    }
}

async function create(req, res) {
    try {
        const result = await maintenanceService.create(req.body, req.user);
        return res.status(201).json({ success: true, message: 'Tạo yêu cầu sửa chữa thành công', data: result });
    } catch (err) {
        return error(res, err);
    }
}

async function update(req, res) {
    try {
        const result = await maintenanceService.update(req.params.id, req.body);
        if (!result) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy yêu cầu sửa chữa' });
        }
        return success(res, result, 'Cập nhật yêu cầu sửa chữa thành công');
    } catch (err) {
        return error(res, err);
    }
}

async function updateStatus(req, res) {
    try {
        const { status, manager_note } = req.body;
        const result = await maintenanceService.updateStatus(req.params.id, status, manager_note);
        if (!result) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy yêu cầu sửa chữa' });
        }
        return success(res, result, 'Cập nhật trạng thái thành công');
    } catch (err) {
        return error(res, err);
    }
}

async function remove(req, res) {
    try {
        const deleted = await maintenanceService.remove(req.params.id);
        if (!deleted) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy yêu cầu sửa chữa' });
        }
        return success(res, null, 'Xóa yêu cầu sửa chữa thành công');
    } catch (err) {
        return error(res, err);
    }
}

module.exports = {
    getAll,
    getById,
    create,
    update,
    updateStatus,
    remove,
};
