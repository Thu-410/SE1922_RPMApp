const express = require('express');
const router = express.Router();
const tenantController = require('./tenant.controller');

router.get('/', tenantController.getAllTenants);
router.get('/', tenantController.getTenantsByRoom);
router.get('/', tenantController.getTenantById);
router.get('/', tenantController.createTenant);
router.get('/', tenantController.updateTenant);
router.get('/', tenantController.deleteTenant);

module.exports = router;