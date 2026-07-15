const service = require('./contract.service');
const list = async (req, res, next) => { try { res.json({ success: true, data: await service.list(req.query) }); } catch (e) { next(e); } };
const getById = async (req, res, next) => { try { res.json({ success: true, data: await service.getById(req.params.id) }); } catch (e) { next(e); } };
const create = async (req, res, next) => { try { res.status(201).json({ success: true, message: 'Tạo hợp đồng thành công', data: await service.create(req.body) }); } catch (e) { next(e); } };
const extend = async (req, res, next) => { try { res.json({ success: true, message: 'Gia hạn hợp đồng thành công', data: await service.extend(req.params.id, req.body) }); } catch (e) { next(e); } };
const terminate = async (req, res, next) => { try { res.json({ success: true, message: 'Kết thúc hợp đồng thành công', data: await service.terminate(req.params.id) }); } catch (e) { next(e); } };
module.exports = { list, getById, create, extend, terminate };
