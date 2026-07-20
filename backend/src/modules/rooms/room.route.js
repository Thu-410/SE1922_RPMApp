const express = require('express');
const controller = require('./room.controller');
const authenticate = require('../../middlewares/auth.middleware');
const authorizeRoles = require('../../middlewares/role.middleware');

const router = express.Router();
router.use(authenticate);
router.get('/', authorizeRoles('manager', 'staff'), controller.list);
router.get('/:id', authorizeRoles('manager', 'staff'), controller.getById);
router.post('/images', authorizeRoles('manager'), controller.uploadImage);
router.post('/', authorizeRoles('manager'), controller.create);
router.put('/:id/status', authorizeRoles('manager'), controller.updateStatus);
router.put('/:id', authorizeRoles('manager'), controller.update);
router.delete('/:id', authorizeRoles('manager'), controller.remove);

module.exports = router;
