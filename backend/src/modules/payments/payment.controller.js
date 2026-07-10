const paymentService = require('./payment.service');

const listPayments = async (req, res, next) => {
  try {
    const result = await paymentService.listPayments(req.query);
    res.json({ success: true, data: result.rows, meta: result.meta });
  } catch (error) { next(error); }
};

const getPayment = async (req, res, next) => {
  try {
    res.json({ success: true, data: await paymentService.getPaymentById(req.params.id) });
  } catch (error) { next(error); }
};

const getInvoicePayments = async (req, res, next) => {
  try {
    res.json({ success: true, data: await paymentService.getInvoicePayments(req.params.invoiceId || req.params.id) });
  } catch (error) { next(error); }
};

const createPayment = async (req, res, next) => {
  try {
    const data = await paymentService.createPayment(
      req.params.invoiceId || req.params.id,
      { ...req.body, createdBy: req.user.id },
    );
    res.status(201).json({ success: true, message: 'Payment confirmed successfully', data });
  } catch (error) { next(error); }
};

module.exports = { listPayments, getPayment, getInvoicePayments, createPayment };
