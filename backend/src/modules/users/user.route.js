const express = require('express');
const authMiddleware = require('../../middlewares/auth.middleware');
const checkRole = require('../../middlewares/role.middleware');
const userController = require('./user.controller');
const {
  validate,
  createUserRules,
  updateUserRules,
  userIdParamRules,
  usersQueryRules,
} = require('../../utils/validators');

const router = express.Router();

router.get('/', authMiddleware, checkRole('manager'), usersQueryRules, validate, userController.getAllUsers);
router.get('/:id', authMiddleware, checkRole('manager'), userIdParamRules, validate, userController.getUserById);
router.post('/', authMiddleware, checkRole('manager'), createUserRules, validate, userController.createUser);
router.put('/:id', authMiddleware, checkRole('manager'), userIdParamRules, updateUserRules, validate, userController.updateUser);
router.delete('/:id', authMiddleware, checkRole('manager'), userIdParamRules, validate, userController.deleteUser);

module.exports = router;
