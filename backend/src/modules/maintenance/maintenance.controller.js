const service = require('./maintenance.service');

const list = async (req, res, next) => {
  try {
    const result = await service.list(req.query, req.user);
    res.json({ success: true, data: result.rows, meta: result.meta });
  } catch (error) { next(error); }
};
const getById = async (req, res, next) => {
  try { res.json({ success: true, data: await service.getById(req.params.id, req.user) }); } catch (error) { next(error); }
};
const create = async (req, res, next) => {
  try { res.status(201).json({ success: true, message: 'Tạo yêu cầu sửa chữa thành công', data: await service.create(req.body, req.user) }); } catch (error) { next(error); }
};
const updateStatus = async (req, res, next) => {
  try { res.json({ success: true, message: 'Cập nhật trạng thái thành công', data: await service.updateStatus(req.params.id, req.body, req.user) }); } catch (error) { next(error); }
};

module.exports = { list, getById, create, updateStatus };
