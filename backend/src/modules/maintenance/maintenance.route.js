const express = require('express');
const controller = require('./maintenance.controller');
const authenticate = require('../../middlewares/auth.middleware');
const authorizeRoles = require('../../middlewares/role.middleware');

const router = express.Router();
router.use(authenticate);
router.get('/', authorizeRoles('manager', 'staff', 'tenant'), controller.list);
router.get('/:id', authorizeRoles('manager', 'staff', 'tenant'), controller.getById);
router.post('/', authorizeRoles('manager', 'staff', 'tenant'), controller.create);
router.put('/:id/status', authorizeRoles('manager', 'staff', 'tenant'), controller.updateStatus);

module.exports = router;
