const crypto = require('crypto');
const { pool } = require('../../config/db');
const AppError = require('../../utils/app-error');
const paymentService = require('./payment.service');

const requiredEnv = (...names) => {
  const missing = names.filter((name) => !process.env[name]);
  if (missing.length) throw new AppError(503, `Cổng thanh toán chưa được cấu hình: ${missing.join(', ')}`);
};

const getTenantInvoice = async (userId, invoiceId) => {
  const [rows] = await pool.execute(
    `SELECT i.id, i.total_amount, i.status, r.room_number
     FROM invoices i JOIN tenants t ON t.id = i.tenant_id JOIN rooms r ON r.id = i.room_id
     WHERE i.id = ? AND t.user_id = ? LIMIT 1`,
    [invoiceId, userId],
  );
  if (!rows.length) throw new AppError(404, 'Không tìm thấy hóa đơn của người thuê');
  if (!['unpaid', 'overdue'].includes(rows[0].status)) throw new AppError(409, 'Hóa đơn không còn khả dụng để thanh toán');
  return rows[0];
};

const invoiceIdFromReference = (reference) => {
  const match = /^INV(\d+)-/.exec(String(reference || ''));
  if (!match) throw new AppError(400, 'Mã tham chiếu thanh toán không hợp lệ');
  return Number(match[1]);
};

const publicUrl = () => {
  requiredEnv('PAYMENT_PUBLIC_URL');
  return process.env.PAYMENT_PUBLIC_URL.replace(/\/$/, '');
};

const createVnpay = async (invoice, ipAddress) => {
  requiredEnv('VNPAY_TMN_CODE', 'VNPAY_HASH_SECRET');
  const reference = `INV${invoice.id}-${Date.now()}`;
  const now = new Date(Date.now() + 7 * 60 * 60 * 1000);
  const format = (date) => date.toISOString().replace(/[-:TZ.]/g, '').slice(0, 14);
  const params = {
    vnp_Amount: String(Math.round(Number(invoice.total_amount) * 100)),
    vnp_Command: 'pay',
    vnp_CreateDate: format(now),
    vnp_CurrCode: 'VND',
    vnp_ExpireDate: format(new Date(now.getTime() + 15 * 60 * 1000)),
    vnp_IpAddr: ipAddress || '127.0.0.1',
    vnp_Locale: 'vn',
    vnp_OrderInfo: `Thanh toan hoa don ${invoice.id} phong ${invoice.room_number}`,
    vnp_OrderType: 'billpayment',
    vnp_ReturnUrl: `${publicUrl()}/api/online-payments/vnpay/return`,
    vnp_TmnCode: process.env.VNPAY_TMN_CODE,
    vnp_TxnRef: reference,
    vnp_Version: '2.1.0',
  };
  const query = new URLSearchParams(Object.entries(params).sort(([a], [b]) => a.localeCompare(b))).toString();
  const signature = crypto.createHmac('sha512', process.env.VNPAY_HASH_SECRET).update(query).digest('hex');
  return `${process.env.VNPAY_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html'}?${query}&vnp_SecureHash=${signature}`;
};

const createMomo = async (invoice) => {
  requiredEnv('MOMO_PARTNER_CODE', 'MOMO_ACCESS_KEY', 'MOMO_SECRET_KEY');
  const orderId = `INV${invoice.id}-${Date.now()}`;
  const amount = String(Math.round(Number(invoice.total_amount)));
  const requestId = orderId;
  const orderInfo = `Thanh toan hoa don ${invoice.id}`;
  const redirectUrl = `${publicUrl()}/api/online-payments/momo/return`;
  const ipnUrl = `${publicUrl()}/api/online-payments/momo/ipn`;
  const requestType = 'captureWallet';
  const extraData = '';
  const raw = `accessKey=${process.env.MOMO_ACCESS_KEY}&amount=${amount}&extraData=${extraData}&ipnUrl=${ipnUrl}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${process.env.MOMO_PARTNER_CODE}&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;
  const body = {
    partnerCode: process.env.MOMO_PARTNER_CODE, requestId, amount, orderId, orderInfo,
    redirectUrl, ipnUrl, requestType, extraData, lang: 'vi',
    signature: crypto.createHmac('sha256', process.env.MOMO_SECRET_KEY).update(raw).digest('hex'),
  };
  const response = await fetch(process.env.MOMO_API_URL || 'https://test-payment.momo.vn/v2/gateway/api/create', {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  const data = await response.json();
  if (!response.ok || Number(data.resultCode) !== 0 || !data.payUrl) throw new AppError(502, data.message || 'MoMo không thể tạo giao dịch');
  return data.payUrl;
};

const paypalAccessToken = async () => {
  requiredEnv('PAYPAL_CLIENT_ID', 'PAYPAL_CLIENT_SECRET');
  const base = process.env.PAYPAL_API_URL || 'https://api-m.sandbox.paypal.com';
  const auth = Buffer.from(`${process.env.PAYPAL_CLIENT_ID}:${process.env.PAYPAL_CLIENT_SECRET}`).toString('base64');
  const response = await fetch(`${base}/v1/oauth2/token`, {
    method: 'POST', headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'grant_type=client_credentials',
  });
  const data = await response.json();
  if (!response.ok) throw new AppError(502, 'Không thể xác thực với PayPal');
  return data.access_token;
};

const createPaypal = async (invoice) => {
  requiredEnv('PAYPAL_VND_PER_USD');
  const rate = Number(process.env.PAYPAL_VND_PER_USD);
  if (!Number.isFinite(rate) || rate <= 0) throw new AppError(500, 'PAYPAL_VND_PER_USD không hợp lệ');
  const token = await paypalAccessToken();
  const base = process.env.PAYPAL_API_URL || 'https://api-m.sandbox.paypal.com';
  const response = await fetch(`${base}/v2/checkout/orders`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', 'PayPal-Request-Id': `invoice-${invoice.id}-${Date.now()}` },
    body: JSON.stringify({
      intent: 'CAPTURE',
      purchase_units: [{ custom_id: String(invoice.id), description: `Hoa don phong ${invoice.room_number}`, amount: { currency_code: 'USD', value: (Number(invoice.total_amount) / rate).toFixed(2) } }],
      payment_source: { paypal: { experience_context: { return_url: `${publicUrl()}/api/online-payments/paypal/return`, cancel_url: `${publicUrl()}/api/online-payments/cancel`, user_action: 'PAY_NOW' } } },
    }),
  });
  const data = await response.json();
  const approval = data.links?.find((link) => link.rel === 'payer-action' || link.rel === 'approve');
  if (!response.ok || !approval) throw new AppError(502, data.message || 'PayPal không thể tạo giao dịch');
  return approval.href;
};

const createCheckout = async (userId, invoiceId, provider, ipAddress) => {
  const invoice = await getTenantInvoice(userId, invoiceId);
  let approvalUrl;
  if (provider === 'momo') approvalUrl = await createMomo(invoice);
  else if (provider === 'vnpay') approvalUrl = await createVnpay(invoice, ipAddress);
  else if (provider === 'paypal') approvalUrl = await createPaypal(invoice);
  else throw new AppError(400, 'Cổng thanh toán phải là momo, vnpay hoặc paypal');
  return { provider, approvalUrl };
};

const verifyVnpay = (query) => {
  requiredEnv('VNPAY_HASH_SECRET');
  const params = { ...query };
  const received = params.vnp_SecureHash;
  delete params.vnp_SecureHash;
  delete params.vnp_SecureHashType;
  const raw = new URLSearchParams(Object.entries(params).sort(([a], [b]) => a.localeCompare(b))).toString();
  const expected = crypto.createHmac('sha512', process.env.VNPAY_HASH_SECRET).update(raw).digest('hex');
  if (typeof received !== 'string' || received.length !== expected.length) return false;
  return crypto.timingSafeEqual(Buffer.from(received), Buffer.from(expected));
};

const handleVnpayIpn = async (query) => {
  if (!verifyVnpay(query)) return { RspCode: '97', Message: 'Invalid signature' };
  if (query.vnp_ResponseCode !== '00' || query.vnp_TransactionStatus !== '00') return { RspCode: '00', Message: 'Payment not successful' };
  const invoiceId = invoiceIdFromReference(query.vnp_TxnRef);
  try {
    await paymentService.createPayment(invoiceId, { amount: Number(query.vnp_Amount) / 100, paymentMethod: 'other', transactionCode: `VNPAY-${query.vnp_TransactionNo}`, note: 'Thanh toán trực tuyến qua VNPay' });
    return { RspCode: '00', Message: 'Confirm Success' };
  } catch (error) {
    if (error.statusCode === 409) return { RspCode: '02', Message: 'Order already confirmed' };
    return { RspCode: '04', Message: 'Invalid amount or order' };
  }
};

const handleMomoIpn = async (body) => {
  requiredEnv('MOMO_ACCESS_KEY', 'MOMO_SECRET_KEY');
  const raw = `accessKey=${process.env.MOMO_ACCESS_KEY}&amount=${body.amount}&extraData=${body.extraData || ''}&message=${body.message}&orderId=${body.orderId}&orderInfo=${body.orderInfo}&orderType=${body.orderType}&partnerCode=${body.partnerCode}&payType=${body.payType}&requestId=${body.requestId}&responseTime=${body.responseTime}&resultCode=${body.resultCode}&transId=${body.transId}`;
  const expected = crypto.createHmac('sha256', process.env.MOMO_SECRET_KEY).update(raw).digest('hex');
  if (!body.signature || body.signature !== expected) throw new AppError(400, 'Chữ ký MoMo không hợp lệ');
  if (Number(body.resultCode) === 0) {
    await paymentService.createPayment(invoiceIdFromReference(body.orderId), { amount: Number(body.amount), paymentMethod: 'momo', transactionCode: `MOMO-${body.transId}`, note: 'Thanh toán trực tuyến qua MoMo' });
  }
};

const capturePaypal = async (orderId) => {
  requiredEnv('PAYPAL_VND_PER_USD');
  const token = await paypalAccessToken();
  const base = process.env.PAYPAL_API_URL || 'https://api-m.sandbox.paypal.com';
  const response = await fetch(`${base}/v2/checkout/orders/${encodeURIComponent(orderId)}/capture`, { method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' } });
  const data = await response.json();
  if (!response.ok || data.status !== 'COMPLETED') throw new AppError(502, 'PayPal chưa xác nhận thanh toán thành công');
  const unit = data.purchase_units?.[0];
  const invoiceId = Number(unit?.payments?.captures?.[0]?.custom_id || unit?.custom_id);
  const capture = unit?.payments?.captures?.[0];
  const transactionId = capture?.id;
  const [invoices] = await pool.execute('SELECT total_amount FROM invoices WHERE id = ? LIMIT 1', [invoiceId]);
  if (!invoices.length) throw new AppError(404, 'Không tìm thấy hóa đơn PayPal');
  const expectedUsd = (Number(invoices[0].total_amount) / Number(process.env.PAYPAL_VND_PER_USD)).toFixed(2);
  if (capture?.amount?.currency_code !== 'USD' || capture?.amount?.value !== expectedUsd) {
    throw new AppError(400, 'Số tiền PayPal không khớp hóa đơn');
  }
  await paymentService.createPayment(invoiceId, { paymentMethod: 'other', transactionCode: `PAYPAL-${transactionId}`, note: `Thanh toán trực tuyến qua PayPal (${unit?.payments?.captures?.[0]?.amount?.value} USD)` });
};

module.exports = { createCheckout, handleVnpayIpn, handleMomoIpn, capturePaypal, verifyVnpay };
