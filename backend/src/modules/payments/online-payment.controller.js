const service = require('./online-payment.service');

const checkout = async (req, res, next) => {
  try {
    const data = await service.createCheckout(req.user.id, req.params.id, req.body.provider, req.ip);
    res.status(201).json({ success: true, message: 'Đã tạo phiên thanh toán', data });
  } catch (error) { next(error); }
};

const vnpayIpn = async (req, res) => res.json(await service.handleVnpayIpn(req.query));
const vnpayReturn = async (req, res, next) => {
  try {
    const valid = service.verifyVnpay(req.query);
    const reference = valid ? String(req.query.vnp_TxnRef || '') : '';
    const invoiceId = /^INV(\d+)-/.exec(reference)?.[1] || '';

    // VNPay normally confirms through IPN. Sandbox configurations do not
    // always call that endpoint, so process the signed return as a safe,
    // idempotent fallback before sending the customer back to the app.
    if (valid) await service.handleVnpayIpn(req.query);

    const params = new URLSearchParams({
      invoiceId,
      responseCode: valid ? String(req.query.vnp_ResponseCode || '99') : '97',
      transactionStatus: valid ? String(req.query.vnp_TransactionStatus || '99') : '97',
    });
    res.redirect(`vnpaypayment://return?${params}`);
  } catch (error) {
    next(error);
  }
};
const momoIpn = async (req, res, next) => {
  try { await service.handleMomoIpn(req.body); res.json({ success: true }); } catch (error) {
    if (error.statusCode === 409) res.json({ success: true, duplicate: true });
    else next(error);
  }
};
const simpleReturn = (req, res) => res.send('<h2>Đã quay lại từ cổng thanh toán</h2><p>Bạn có thể quay lại ứng dụng để kiểm tra hóa đơn.</p>');
const paypalReturn = async (req, res, next) => {
  try { await service.capturePaypal(req.query.token); res.send('<h2>Thanh toán PayPal thành công</h2><p>Bạn có thể quay lại ứng dụng.</p>'); } catch (error) { next(error); }
};

module.exports = { checkout, vnpayIpn, vnpayReturn, momoIpn, simpleReturn, paypalReturn };
