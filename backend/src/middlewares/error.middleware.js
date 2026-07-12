const { error } = require('../utils/response');

const errorMiddleware = (err, req, res, next) => {
  // Log the original error on the server for debugging, but never expose it in production 5xx responses.
  console.error('[Error middleware]', err);

  if (err.code === 'ER_DUP_ENTRY') {
    return error(res, 'Email already exists', 409);
  }

  const statusCode = Number.isInteger(err.statusCode) ? err.statusCode : 500;
  const isServerError = statusCode >= 500;

  if (!isServerError) {
    return error(res, err.message || 'Đã xảy ra lỗi', statusCode);
  }

  const responseBody = {
    success: false,
    message: 'Đã xảy ra lỗi hệ thống, vui lòng thử lại sau.',
  };

  if (process.env.NODE_ENV === 'development') {
    responseBody.details = err.message;
    responseBody.stack = err.stack;
  }

  return res.status(statusCode).json(responseBody);
};

module.exports = errorMiddleware;
