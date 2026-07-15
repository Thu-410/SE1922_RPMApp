const express = require('express');
const cors = require('cors');
const path = require('path');

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
const maintenanceRouter = require('./modules/maintenance/maintenance.route');
const reportRouter = require('./modules/reports/report.route');
const dashboardRouter = require('./modules/dashboard/dashboard.route');
const roomRouter = require('./modules/rooms/room.route');
const tenantRouter = require('./modules/tenants/tenant.route');
const contractRouter = require('./modules/contracts/contract.route');

const app = express();

app.disable('x-powered-by');
const allowedOrigins = String(process.env.CORS_ORIGIN || '').split(',').map((value) => value.trim()).filter(Boolean);
app.use(cors({ origin: allowedOrigins.length ? allowedOrigins : true, methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'] }));
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  next();
});
app.use(express.json({ limit: '8mb' }));
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

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
app.use('/api/maintenance-requests', maintenanceRouter);
app.use('/api/reports', reportRouter);
app.use('/api/dashboard', dashboardRouter);
app.use('/api/rooms', roomRouter);
app.use('/api/tenants', tenantRouter);
app.use('/api/contracts', contractRouter);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
