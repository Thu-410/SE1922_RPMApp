const { body, param, query, validationResult } = require('express-validator');
const { error } = require('./response');

const PHONE_MESSAGE = 'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0';
// Chữ + số chỉ là khuyến nghị; không dùng matches() để tránh biến nó thành điều kiện bắt buộc.
const PASSWORD_MESSAGE = 'Mật khẩu phải có ít nhất 6 ký tự. Khuyến nghị có ít nhất 1 chữ và 1 số';

const validate = (req, res, next) => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    return error(res, errors.array()[0].msg, 400);
  }

  return next();
};

const registerRules = [
  body('full_name').trim().notEmpty().withMessage('Full name is required'),
  body('email').trim().notEmpty().withMessage('Email is required').isEmail().withMessage('Valid email is required'),
  body('password').notEmpty().withMessage('Password is required').isLength({ min: 6 }).withMessage(PASSWORD_MESSAGE),
  body('phone').trim().notEmpty().withMessage('Phone is required').matches(/^0\d{9}$/).withMessage(PHONE_MESSAGE),
];

const loginRules = [
  body('email').trim().notEmpty().withMessage('Email is required').isEmail().withMessage('Valid email is required'),
  body('password').notEmpty().withMessage('Password is required'),
];

const updateProfileRules = [
  body('full_name').trim().notEmpty().withMessage('Full name is required'),
  body('phone').trim().notEmpty().withMessage('Phone is required').matches(/^0\d{9}$/).withMessage(PHONE_MESSAGE),
];

const changePasswordRules = [
  body('old_password').notEmpty().withMessage('Old password is required'),
  body('new_password').notEmpty().withMessage('New password is required').isLength({ min: 6 }).withMessage(PASSWORD_MESSAGE),
];

const createUserRules = [
  body('full_name').trim().notEmpty().withMessage('Full name is required'),
  body('email').trim().notEmpty().withMessage('Email is required').isEmail().withMessage('Valid email is required'),
  body('password').optional().isLength({ min: 6 }).withMessage(PASSWORD_MESSAGE),
  body('phone').optional({ values: 'falsy' }).trim().matches(/^0\d{9}$/).withMessage(PHONE_MESSAGE),
  body('role').optional().isIn(['staff', 'tenant']).withMessage("Role chỉ có thể là 'staff' hoặc 'tenant'"),
  body('status').optional().isIn(['active', 'inactive', 'locked']).withMessage('Invalid status'),
];

const updateUserRules = [
  body('full_name').trim().notEmpty().withMessage('Full name is required'),
  body('phone').optional({ values: 'falsy' }).trim().matches(/^0\d{9}$/).withMessage(PHONE_MESSAGE),
  body('role').notEmpty().withMessage('Role is required').isIn(['manager', 'staff', 'tenant']).withMessage('Invalid role'),
  body('status').notEmpty().withMessage('Status is required').isIn(['active', 'inactive', 'locked']).withMessage('Invalid status'),
];

const userIdParamRules = [
  param('id').isInt({ min: 1 }).withMessage('ID không hợp lệ').toInt(),
];

const usersQueryRules = [
  query('page').optional().isInt({ min: 1 }).withMessage('page phải là số nguyên dương').toInt(),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('limit phải là số nguyên từ 1 đến 100')
    .toInt(),
  query('role')
    .optional()
    .isIn(['manager', 'staff', 'tenant'])
    .withMessage('role không hợp lệ'),
  query('status')
    .optional()
    .isIn(['active', 'inactive', 'locked'])
    .withMessage('status không hợp lệ'),
];

module.exports = {
  validate,
  registerRules,
  loginRules,
  updateProfileRules,
  changePasswordRules,
  createUserRules,
  updateUserRules,
  userIdParamRules,
  usersQueryRules,
};
