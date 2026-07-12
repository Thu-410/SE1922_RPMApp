const authService = require('./auth.service');
const { success } = require('../../utils/response');

const register = async (req, res, next) => {
  try {
    const result = await authService.registerUser(req.body);
    return success(res, result, 'Register successfully', 201);
  } catch (err) {
    return next(err);
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const result = await authService.loginUser(email, password);
    return success(res, result, 'Login successfully');
  } catch (err) {
    return next(err);
  }
};

const getProfile = async (req, res, next) => {
  try {
    const result = await authService.getProfile(req.user.id);
    return success(res, result, 'Get profile successfully');
  } catch (err) {
    return next(err);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const result = await authService.updateProfile(req.user.id, req.body);
    return success(res, result, 'Update profile successfully');
  } catch (err) {
    return next(err);
  }
};

const changePassword = async (req, res, next) => {
  try {
    const { old_password, new_password } = req.body;
    await authService.changePassword(req.user.id, old_password, new_password);
    return success(res, null, 'Change password successfully');
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  changePassword,
};
