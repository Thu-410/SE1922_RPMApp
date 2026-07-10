const utilityService = require('./utility.service');
const servicePriceService = require('./service-price.service');

const listReadings = async (req, res, next) => {
  try {
    const result = await utilityService.listReadings(req.query);
    res.json({ success: true, data: result.rows, meta: result.meta });
  } catch (error) { next(error); }
};

const getRoomOptions = async (req, res, next) => {
  try {
    res.json({ success: true, data: await utilityService.getRoomOptions() });
  } catch (error) { next(error); }
};

const getReading = async (req, res, next) => {
  try {
    res.json({ success: true, data: await utilityService.getReadingById(req.params.id) });
  } catch (error) { next(error); }
};

const createReading = async (req, res, next) => {
  try {
    const data = await utilityService.createReading({ ...req.body, createdBy: req.user.id });
    res.status(201).json({ success: true, message: 'Utility reading created successfully', data });
  } catch (error) { next(error); }
};

const updateReading = async (req, res, next) => {
  try {
    const data = await utilityService.updateReading(req.params.id, req.body);
    res.json({ success: true, message: 'Utility reading updated successfully', data });
  } catch (error) { next(error); }
};

const deleteReading = async (req, res, next) => {
  try {
    await utilityService.deleteReading(req.params.id);
    res.json({ success: true, message: 'Utility reading deleted successfully' });
  } catch (error) { next(error); }
};

const listPrices = async (req, res, next) => {
  try {
    res.json({ success: true, data: await servicePriceService.getPrices() });
  } catch (error) { next(error); }
};

const getCurrentPrice = async (req, res, next) => {
  try {
    res.json({ success: true, data: await servicePriceService.getCurrentPrice() });
  } catch (error) { next(error); }
};

const getPrice = async (req, res, next) => {
  try {
    res.json({ success: true, data: await servicePriceService.getPriceById(req.params.id) });
  } catch (error) { next(error); }
};

const createPrice = async (req, res, next) => {
  try {
    const data = await servicePriceService.createPrice(req.body);
    res.status(201).json({ success: true, message: 'Service price created successfully', data });
  } catch (error) { next(error); }
};

const updatePrice = async (req, res, next) => {
  try {
    const data = await servicePriceService.updatePrice(req.params.id, req.body);
    res.json({ success: true, message: 'Service price updated successfully', data });
  } catch (error) { next(error); }
};

module.exports = {
  getRoomOptions,
  listReadings,
  getReading,
  createReading,
  updateReading,
  deleteReading,
  listPrices,
  getCurrentPrice,
  getPrice,
  createPrice,
  updatePrice,
};
