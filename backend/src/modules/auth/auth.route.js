const express = require('express');
const controller = require('./auth.controller');
const authenticate = require('../../middlewares/auth.middleware');

const router = express.Router();
router.post('/login', controller.login);
router.post('/register', controller.register);
router.get('/profile', authenticate, controller.profile);
router.put('/profile', authenticate, controller.updateProfile);
router.put('/change-password', authenticate, controller.changePassword);

module.exports = router;
