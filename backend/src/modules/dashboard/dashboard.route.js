const express = require('express');
const controller = require('./dashboard.controller');
const auth = require('../../middlewares/auth.middleware');
const role = require('../../middlewares/role.middleware');

const router = express.Router();

router.use(auth);
router.get('/summary', role('Manager', 'Staff'), controller.getSummary);
router.get('/revenue-overview', role('Manager', 'Staff'), controller.getRevenueOverview);
router.get('/recent-maintenance', role('Manager', 'Staff'), controller.getRecentMaintenance);

module.exports = router;
