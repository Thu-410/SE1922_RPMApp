const service = require('./room.service');

const list = async (req, res, next) => { try { res.json({ success: true, data: await service.list(req.query) }); } catch (error) { next(error); } };
const getById = async (req, res, next) => { try { res.json({ success: true, data: await service.getById(req.params.id) }); } catch (error) { next(error); } };
const create = async (req, res, next) => { try { res.status(201).json({ success: true, message: 'Thêm phòng thành công', data: await service.create(req.body) }); } catch (error) { next(error); } };
const update = async (req, res, next) => { try { res.json({ success: true, message: 'Cập nhật phòng thành công', data: await service.update(req.params.id, req.body) }); } catch (error) { next(error); } };
const updateStatus = async (req, res, next) => { try { res.json({ success: true, message: 'Cập nhật trạng thái phòng thành công', data: await service.update(req.params.id, { status: req.body.status }) }); } catch (error) { next(error); } };
const remove = async (req, res, next) => { try { await service.remove(req.params.id); res.json({ success: true, message: 'Đã chuyển phòng vào lịch sử' }); } catch (error) { next(error); } };
const uploadImage = async (req, res, next) => {
  try {
    const path = await service.uploadImage(req.body);
    const url = `${req.protocol}://${req.get('host')}${path}`;
    res.status(201).json({ success: true, message: 'Tải ảnh phòng thành công', data: { url } });
  } catch (error) { next(error); }
};

module.exports = { list, getById, create, update, updateStatus, remove, uploadImage };
