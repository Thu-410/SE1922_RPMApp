const service = require('./report.service');

const response = (method) => async (req, res, next) => {
  try { res.json({ success: true, data: await service[method](req.query) }); } catch (error) { next(error); }
};

module.exports = { revenue: response('revenue'), occupancy: response('occupancy'), debts: response('debts') };
