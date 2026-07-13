const jwt = require('jsonwebtoken');

const generateToken = (user) => {
  if (!process.env.JWT_SECRET) {
    const error = new Error('JWT_SECRET is not configured');
    error.statusCode = 500;
    throw error;
  }

  return jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    {
      subject: String(user.id),
      issuer: process.env.JWT_ISSUER || 'rental-management-api',
      expiresIn: process.env.JWT_EXPIRES_IN || '1d',
      algorithm: 'HS256',
    },
  );
};

module.exports = generateToken;
