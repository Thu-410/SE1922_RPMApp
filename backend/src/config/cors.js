const configuredOrigins = (process.env.ALLOWED_ORIGIN || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

const allowLocalhostByDefault = process.env.NODE_ENV !== 'production' && configuredOrigins.length === 0;

const isLocalhostOrigin = (origin) => {
  try {
    const { hostname, protocol } = new URL(origin);
    const isHttp = protocol === 'http:' || protocol === 'https:';
    return isHttp && (hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '::1');
  } catch (err) {
    return false;
  }
};

const corsOptions = {
  origin(origin, callback) {
    // Requests without Origin (mobile apps, Postman, server-to-server) are not browser CORS requests.
    const isAllowed = !origin
      || configuredOrigins.includes(origin)
      || (allowLocalhostByDefault && isLocalhostOrigin(origin));

    return callback(null, isAllowed);
  },
};

module.exports = corsOptions;
