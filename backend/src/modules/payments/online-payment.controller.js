const service = require('./online-payment.service');

const checkout = async (req, res, next) => {
  try {
    const data = await service.createCheckout(req.user.id, req.params.id, req.body.provider, req.ip);
    res.status(201).json({ success: true, message: 'Đã tạo phiên thanh toán', data });
  } catch (error) { next(error); }
};

const vnpayIpn = async (req, res) => res.json(await service.handleVnpayIpn(req.query));
const vnpayReturn = (req, res) => res.send(`<h2>${service.verifyVnpay(req.query) && req.query.vnp_ResponseCode === '00' ? 'Thanh toán đã được tiếp nhận' : 'Thanh toán không thành công'}</h2><p>Bạn có thể quay lại ứng dụng.</p>`);
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
