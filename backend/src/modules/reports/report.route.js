const express = require('express');
const controller = require('./report.controller');
const auth = require('../../middlewares/auth.middleware');
const role = require('../../middlewares/role.middleware');

const router = express.Router();

router.use(auth);
router.get('/revenue', role('Manager', 'Staff'), controller.getRevenueReport);
router.get('/occupancy', role('Manager', 'Staff'), controller.getOccupancyReport);
router.get('/debts', role('Manager', 'Staff'), controller.getDebtReport);

module.exports = router;
