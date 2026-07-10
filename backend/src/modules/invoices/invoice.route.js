const express = require('express');
const controller = require('./invoice.controller');
const paymentController = require('../payments/payment.controller');
const authenticate = require('../../middlewares/auth.middleware');
const authorizeRoles = require('../../middlewares/role.middleware');

const router = express.Router();
router.use(authenticate);
router.use(authorizeRoles('manager', 'staff'));

router.get('/', controller.listInvoices);
router.get('/:invoiceId/payments', paymentController.getInvoicePayments);
router.get('/:id', controller.getInvoice);
router.post('/preview', controller.previewInvoice);
router.post('/', controller.createInvoice);
router.post('/:invoiceId/payments', paymentController.createPayment);
router.put('/status/overdue', controller.markOverdueInvoices);
router.put('/:id/cancel', authorizeRoles('manager'), controller.cancelInvoice);
router.put('/:id/payment', paymentController.createPayment);
router.put('/:id', controller.updateInvoice);

module.exports = router;
