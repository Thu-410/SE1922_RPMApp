const express = require('express');
const controller = require('./invoice.controller');
const authenticate = require('../../middlewares/auth.middleware');
const authorizeRoles = require('../../middlewares/role.middleware');

const router = express.Router();
router.use(authenticate);
router.use(authorizeRoles('tenant'));
router.get('/', controller.listMyInvoices);
router.get('/:id', controller.getMyInvoice);

module.exports = router;
