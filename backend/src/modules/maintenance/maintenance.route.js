const express = require('express');
const controller = require('./maintenance.controller');
const auth = require('../../middlewares/auth.middleware');
const role = require('../../middlewares/role.middleware');

const router = express.Router();

router.use(auth);

// Manager/Staff xem tất cả; Tenant chỉ xem yêu cầu của mình ở service layer.
router.get('/', role('Manager', 'Staff', 'Tenant'), controller.getAll);
router.get('/:id', role('Manager', 'Staff', 'Tenant'), controller.getById);

// Tenant tạo yêu cầu; Manager/Staff cũng có thể tạo hộ.
router.post('/', role('Manager', 'Staff', 'Tenant'), controller.create);

// Chỉ Manager/Staff sửa nội dung hoặc cập nhật trạng thái xử lý.
router.put('/:id', role('Manager', 'Staff'), controller.update);
router.put('/:id/status', role('Manager', 'Staff'), controller.updateStatus);
router.delete('/:id', role('Manager'), controller.remove);

module.exports = router;