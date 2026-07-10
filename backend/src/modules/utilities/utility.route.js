const express = require('express');
const controller = require('./utility.controller');
const authenticate = require('../../middlewares/auth.middleware');
const authorizeRoles = require('../../middlewares/role.middleware');

const utilityReadingRouter = express.Router();
utilityReadingRouter.use(authenticate);
utilityReadingRouter.get('/', controller.listReadings);
utilityReadingRouter.get('/room-options', authorizeRoles('manager', 'staff'), controller.getRoomOptions);
utilityReadingRouter.get('/:id', controller.getReading);
utilityReadingRouter.post('/', authorizeRoles('manager', 'staff'), controller.createReading);
utilityReadingRouter.put('/:id', authorizeRoles('manager', 'staff'), controller.updateReading);
utilityReadingRouter.delete('/:id', authorizeRoles('manager'), controller.deleteReading);

const servicePriceRouter = express.Router();
servicePriceRouter.use(authenticate);
servicePriceRouter.use(authorizeRoles('manager', 'staff'));
servicePriceRouter.get('/', controller.listPrices);
servicePriceRouter.get('/current', controller.getCurrentPrice);
servicePriceRouter.get('/:id', controller.getPrice);
servicePriceRouter.post('/', authorizeRoles('manager'), controller.createPrice);
servicePriceRouter.put('/:id', authorizeRoles('manager'), controller.updatePrice);

module.exports = { utilityReadingRouter, servicePriceRouter };
