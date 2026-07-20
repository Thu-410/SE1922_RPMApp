const express = require('express');
const controller = require('./report.controller');
const authenticate = require('../../middlewares/auth.middleware');
const authorizeRoles = require('../../middlewares/role.middleware');

const router = express.Router();
router.use(authenticate, authorizeRoles('manager', 'staff'));
router.get('/revenue', controller.revenue);
router.get('/occupancy', controller.occupancy);
router.get('/debts', controller.debts);
module.exports = router;
