const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} not found`,
  });
};

// Express recognizes error middleware by its four parameters.
// eslint-disable-next-line no-unused-vars
const errorHandler = (error, req, res, next) => {
  const statusCode = error.statusCode || error.status || 500;
  const isProduction = process.env.NODE_ENV === 'production';

  console.error(error);

  res.status(statusCode).json({
    success: false,
    message: statusCode === 500 && isProduction
      ? 'Internal server error'
      : error.message || 'Internal server error',
    ...(error.errors ? { errors: error.errors } : {}),
    ...(!isProduction && error.stack ? { stack: error.stack } : {}),
  });
};

module.exports = {
  notFoundHandler,
  errorHandler,
};
