const service = require('./tenant.service');
const list = async (req, res, next) => { try { res.json({ success: true, data: await service.list(req.query) }); } catch (e) { next(e); } };
const getById = async (req, res, next) => { try { res.json({ success: true, data: await service.getById(req.params.id) }); } catch (e) { next(e); } };
const create = async (req, res, next) => { try { res.status(201).json({ success: true, message: 'Thêm người thuê thành công', data: await service.create(req.body) }); } catch (e) { next(e); } };
const update = async (req, res, next) => { try { res.json({ success: true, message: 'Cập nhật người thuê thành công', data: await service.update(req.params.id, req.body) }); } catch (e) { next(e); } };
const remove = async (req, res, next) => { try { await service.remove(req.params.id); res.json({ success: true, message: 'Đã cập nhật người thuê thành rời đi' }); } catch (e) { next(e); } };
module.exports = { list, getById, create, update, remove };
