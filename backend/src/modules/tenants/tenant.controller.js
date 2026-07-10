const tenantService = require('./tenant.service');

const getAllTenants = (req, res) => {
    tenantService.getAllTenants((err, results) => {
        if (err) {
            return res.status(500).json({ success: false, message: 'Server Error', error: err });
        }
        res.json({ success: true, data: results });
    });
};

const getTenantById = (req, res) => {
    const { id } = req.params;
    tenantService.getTenantById(id, (err, results) => {
        if (err) return res.status(500).json({ success: false, message: 'Server Error', error: err });
        if (results.length === 0) {
            return res.status(404).json({ success: false, message: 'Tennant not fount' });
        }
        res.json({ success: true, data: results[0] });
    });
};

const getTenantsByRoom = (req, res) => {
    const { roomId } = req.params;
    tenantService.getTenantsByRoom(roomId, (err, results) => {
        if (err) return res.status(500).json({ success: false, message: 'Server Error', error: err });
        res.json({ success: true, data: results });
    });
};

const createTenant = (req, res) => {
    const { full_name, phone } = req.body;

    if (!full_name || !phone) {
        return res.status(400).json({ success: false, message: 'full_name and phone must required' });
    }

    tenantService.createTenant(req.body, (err, results) => {
        if (err) {
            if (err.code === 'ER_DUP_ENTRY') {
                return res.status(409).json({ success: false, message: 'CCCD has existed' });
            }
            return res.status(500).json({ success: false, message: 'Server Error', error: err });
        }
        res.status(201).json({ success: true, message: 'New Tenant has been created', data: { id: results.insertId } });
    });
};

const updateTenant = (req, res) => {
    const { id } = req.params;
    const { full_name, phone } = req.body;

    if (!full_name || !phone) {
        return res.status(400).json({ success: false, message: 'full_name and phone must required' });
    }

    tenantService.updateTenant(id, req.body, (err, results) => {
        if (err) {
            if (err.code === 'ER_DUP_ENTRY') {
                return res.status(409).json({ success: false, message: 'CCCD has existed' });
            }
            return res.status(500).json({ success: false, message: 'Server Error', error: err });
        }
        if (results.affectedRows === 0) {
            return res.status(404).json({ success: false, message: 'Tenant not found' });
        }
        res.json({ success: true, message: 'Update tennant information success' });
    });
};

const deleteTenant = (req, res) => {
    const { id } = req.params;
    tenantService.deleteTenant(id, (err, result) => {
        if (err) return res.status(500).json({ success: false, message: 'Loi server', error: err });
        if (result.affectedRows === 0) {
            return res.status(404).json({ success: false, message: 'Khong tim thay tenant' });
        }
        res.json({ success: true, message: 'Xoa tenant thanh cong' });
    });
};

module.exports = {
    getAllTenants,
    getTenantById,
    getTenantsByRoom,
    createTenant,
    updateTenant,
    deleteTenant
};