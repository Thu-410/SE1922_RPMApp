const express = require('express');
const cors = require('cors');

const { pool } = require('./config/db');
const { notFoundHandler, errorHandler } = require('./middlewares/error.middleware');
const {
  utilityReadingRouter,
  servicePriceRouter,
} = require('./modules/utilities/utility.route');
const invoiceRouter = require('./modules/invoices/invoice.route');
const paymentRouter = require('./modules/payments/payment.route');
const tenantInvoiceRouter = require('./modules/invoices/tenant-invoice.route');
const authenticate = require('./middlewares/auth.middleware');
const authRouter = require('./modules/auth/auth.route');
const { publicRouter: onlinePaymentRouter, tenantRouter: tenantCheckoutRouter } = require('./modules/payments/online-payment.route');

const app = express();

app.disable('x-powered-by');
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Welcome to the Rental Management API',
    data: {
      healthCheck: '/api/health',
      apiPrefix: '/api',
    },
  });
});

app.get('/api/health', async (req, res, next) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({
      success: true,
      message: 'Rental management API is running',
      data: {
        database: 'connected',
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    next(error);
  }
});

app.get('/api/session', authenticate, (req, res) => {
  res.json({ success: true, data: req.user });
});

app.use('/api/auth', authRouter);
app.use('/api/online-payments', onlinePaymentRouter);

app.use('/api/utility-readings', utilityReadingRouter);
app.use('/api/service-prices', servicePriceRouter);
app.use('/api/invoices', invoiceRouter);
app.use('/api/payments', paymentRouter);
app.use('/api/tenants/me/invoices', tenantInvoiceRouter);
app.use('/api/tenants/me/invoices', tenantCheckoutRouter);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
