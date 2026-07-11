const express = require('express');
const router = express.Router();
const contractController = require('./contract.controller');

router.get('/', contractController.getAllContracts);
router.get('/tenant/:tenantId', contractController.getContractsByTenant);
router.get('/:id', contractController.getContractById);
router.post('/', contractController.createContract);
router.put('/:id/extend', contractController.extendContract);
router.put('/:id/terminate', contractController.terminateContract);

module.exports = router;