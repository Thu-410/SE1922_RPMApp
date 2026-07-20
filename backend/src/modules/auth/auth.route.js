const express = require('express');
const controller = require('./auth.controller');
const authenticate = require('../../middlewares/auth.middleware');
const authRateLimit = require('../../middlewares/rate-limit.middleware');

const router = express.Router();
router.post('/login', authRateLimit, controller.login);
router.post('/register', authRateLimit, controller.register);
router.get('/profile', authenticate, controller.profile);
router.put('/profile', authenticate, controller.updateProfile);
router.put('/change-password', authenticate, controller.changePassword);

module.exports = router;
