const userService = require('./user.service');
const { success } = require('../../utils/response');

const getAllUsers = async (req, res, next) => {
  try {
    const result = await userService.getAllUsers(req.query);
    return success(res, result, 'Get users successfully');
  } catch (err) {
    return next(err);
  }
};

const getUserById = async (req, res, next) => {
  try {
    const user = await userService.getUserById(req.params.id);
    return success(res, user, 'Get user successfully');
  } catch (err) {
    return next(err);
  }
};

const createUser = async (req, res, next) => {
  try {
    const result = await userService.createUser(req.body);
    return success(res, result, 'Create user successfully', 201);
  } catch (err) {
    return next(err);
  }
};

const updateUser = async (req, res, next) => {
  try {
    const user = await userService.updateUser(req.params.id, req.body, req.user.id);
    return success(res, user, 'Update user successfully');
  } catch (err) {
    return next(err);
  }
};

const deleteUser = async (req, res, next) => {
  try {
    const user = await userService.deleteUser(req.params.id, req.user.id);
    return success(res, user, 'Delete user successfully');
  } catch (err) {
    return next(err);
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
};
