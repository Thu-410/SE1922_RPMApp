const { rateLimit } = require('express-rate-limit');
const { error } = require('../utils/response');

const createRateLimitHandler = (fallbackMinutes) => (req, res) => {
  const resetTime = req.rateLimit?.resetTime?.getTime();
  const remainingMinutes = resetTime
    ? Math.max(1, Math.ceil((resetTime - Date.now()) / (60 * 1000)))
    : fallbackMinutes;

  return error(res, `Quá nhiều lần thử, vui lòng thử lại sau ${remainingMinutes} phút`, 429);
};

const loginRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  handler: createRateLimitHandler(15),
});

const registerRateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: createRateLimitHandler(60),
});

module.exports = {
  loginRateLimiter,
  registerRateLimiter,
};
