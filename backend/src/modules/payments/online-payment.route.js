const express = require('express');
const controller = require('./online-payment.controller');
const authenticate = require('../../middlewares/auth.middleware');
const authorizeRoles = require('../../middlewares/role.middleware');

const publicRouter = express.Router();
publicRouter.get('/vnpay/ipn', controller.vnpayIpn);
publicRouter.get('/vnpay/return', controller.vnpayReturn);
publicRouter.post('/momo/ipn', controller.momoIpn);
publicRouter.get('/momo/return', controller.simpleReturn);
publicRouter.get('/paypal/return', controller.paypalReturn);
publicRouter.get('/cancel', controller.simpleReturn);

const tenantRouter = express.Router();
tenantRouter.post('/:id/checkout', authenticate, authorizeRoles('tenant'), controller.checkout);

module.exports = { publicRouter, tenantRouter };
