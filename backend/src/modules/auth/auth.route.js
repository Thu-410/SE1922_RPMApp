const express = require('express');
const authController = require('./auth.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const {
  loginRateLimiter,
  registerRateLimiter,
} = require('../../middlewares/authRateLimit.middleware');
const {
  validate,
  registerRules,
  loginRules,
  updateProfileRules,
  changePasswordRules,
} = require('../../utils/validators');

const router = express.Router();

router.post('/register', registerRateLimiter, registerRules, validate, authController.register);
router.post('/login', loginRateLimiter, loginRules, validate, authController.login);
router.get('/profile', authMiddleware, authController.getProfile);
router.put('/profile', authMiddleware, updateProfileRules, validate, authController.updateProfile);
router.put('/change-password', authMiddleware, changePasswordRules, validate, authController.changePassword);

module.exports = router;
