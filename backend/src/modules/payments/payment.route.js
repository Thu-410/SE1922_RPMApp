const express = require('express');
const controller = require('./payment.controller');
const authenticate = require('../../middlewares/auth.middleware');
const authorizeRoles = require('../../middlewares/role.middleware');

const router = express.Router();
router.use(authenticate);
router.use(authorizeRoles('manager', 'staff'));
router.get('/', controller.listPayments);
router.get('/:id', controller.getPayment);

module.exports = router;
