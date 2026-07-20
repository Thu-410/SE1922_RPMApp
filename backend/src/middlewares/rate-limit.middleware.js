const attempts = new Map();

const authRateLimit = (req, res, next) => {
  const windowMs = 15 * 60 * 1000;
  const maxAttempts = 10;
  const now = Date.now();
  const email = String(req.body?.email || '').trim().toLowerCase();
  const key = `${req.ip}:${email}`;
  const current = attempts.get(key);
  if (!current || current.resetAt <= now) attempts.set(key, { count: 1, resetAt: now + windowMs });
  else {
    current.count += 1;
    if (current.count > maxAttempts) {
      res.setHeader('Retry-After', String(Math.ceil((current.resetAt - now) / 1000)));
      return res.status(429).json({ success: false, message: 'Bạn đã thử quá nhiều lần. Vui lòng đợi 15 phút rồi thử lại.' });
    }
  }
  res.on('finish', () => { if (res.statusCode < 400) attempts.delete(key); });
  return next();
};
module.exports = authRateLimit;
