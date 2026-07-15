const invoiceService = require('./invoice.service');

const previewInvoice = async (req, res, next) => {
  try {
    const data = await invoiceService.previewInvoice(req.body);
    res.json({ success: true, message: 'Đã tính thử hóa đơn', data });
  } catch (error) { next(error); }
};

const createInvoice = async (req, res, next) => {
  try {
    const data = await invoiceService.createInvoice({ ...req.body, createdBy: req.user.id });
    res.status(201).json({ success: true, message: 'Tạo hóa đơn thành công', data });
  } catch (error) { next(error); }
};

const listInvoices = async (req, res, next) => {
  try {
    const result = await invoiceService.listInvoices(req.query);
    res.json({ success: true, data: result.rows, meta: result.meta });
  } catch (error) { next(error); }
};

const getInvoice = async (req, res, next) => {
  try {
    res.json({ success: true, data: await invoiceService.getInvoiceById(req.params.id) });
  } catch (error) { next(error); }
};

const updateInvoice = async (req, res, next) => {
  try {
    const data = await invoiceService.updateInvoice(req.params.id, req.body);
    res.json({ success: true, message: 'Cập nhật và tính lại hóa đơn thành công', data });
  } catch (error) { next(error); }
};

const cancelInvoice = async (req, res, next) => {
  try {
    const data = await invoiceService.cancelInvoice(req.params.id, req.body);
    res.json({ success: true, message: 'Hủy hóa đơn thành công', data });
  } catch (error) { next(error); }
};

const markOverdueInvoices = async (req, res, next) => {
  try {
    const data = await invoiceService.markOverdueInvoices();
    res.json({ success: true, message: 'Đã cập nhật các hóa đơn quá hạn', data });
  } catch (error) { next(error); }
};

const listMyInvoices = async (req, res, next) => {
  try {
    const result = await invoiceService.listMyInvoices(req.user.id, req.query);
    res.json({ success: true, data: result.rows, meta: result.meta });
  } catch (error) { next(error); }
};

const getMyInvoice = async (req, res, next) => {
  try {
    res.json({ success: true, data: await invoiceService.getMyInvoiceById(req.user.id, req.params.id) });
  } catch (error) { next(error); }
};

module.exports = {
  previewInvoice,
  createInvoice,
  listInvoices,
  getInvoice,
  updateInvoice,
  cancelInvoice,
  markOverdueInvoices,
  listMyInvoices,
  getMyInvoice,
};
