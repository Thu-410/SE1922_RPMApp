const service = require('./dashboard.service');
const response = (method) => async (req, res, next) => {
  try { res.json({ success: true, data: await service[method](req.query) }); } catch (error) { next(error); }
};
module.exports = { summary: response('summary'), revenueOverview: response('revenueOverview'), recentMaintenance: response('recentMaintenance') };
