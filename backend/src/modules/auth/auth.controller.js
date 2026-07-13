const authService = require('./auth.service');

const login = async (req, res, next) => {
  try { res.json({ success: true, message: 'Đăng nhập thành công', data: await authService.login(req.body) }); }
  catch (error) { next(error); }
};

const register = async (req, res, next) => {
  try { res.status(201).json({ success: true, message: 'Đăng ký thành công', data: await authService.register(req.body) }); }
  catch (error) { next(error); }
};

const profile = async (req, res, next) => {
  try { res.json({ success: true, data: await authService.getProfile(req.user.id) }); }
  catch (error) { next(error); }
};

const updateProfile = async (req, res, next) => {
  try { res.json({ success: true, message: 'Cập nhật hồ sơ thành công', data: await authService.updateProfile(req.user.id, req.body) }); }
  catch (error) { next(error); }
};

const changePassword = async (req, res, next) => {
  try {
    await authService.changePassword(req.user.id, req.body.old_password, req.body.new_password);
    res.json({ success: true, message: 'Đổi mật khẩu thành công' });
  } catch (error) { next(error); }
};

module.exports = { login, register, profile, updateProfile, changePassword };
