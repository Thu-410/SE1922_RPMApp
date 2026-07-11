const contractService = require('./contract.service');

const getAllContracts = (req, res) => {
  contractService.getAllContracts((err, results) => {
    if (err) return res.status(500).json({ success: false, message: 'Loi server', error: err });
    res.json({ success: true, data: results });
  });
};

const getContractById = (req, res) => {
  const { id } = req.params;
  contractService.getContractById(id, (err, results) => {
    if (err) return res.status(500).json({ success: false, message: 'Loi server', error: err });
    if (results.length === 0) {
      return res.status(404).json({ success: false, message: 'Khong tim thay hop dong' });
    }
    res.json({ success: true, data: results[0] });
  });
};

const getContractsByTenant = (req, res) => {
  const { tenantId } = req.params;
  contractService.getContractsByTenant(tenantId, (err, results) => {
    if (err) return res.status(500).json({ success: false, message: 'Loi server', error: err });
    res.json({ success: true, data: results });
  });
};

const createContract = (req, res) => {
  const { room_id, tenant_id, start_date, end_date, monthly_price } = req.body;

  if (!room_id || !tenant_id || !start_date || !end_date || !monthly_price) {
    return res.status(400).json({
      success: false,
      message: 'room_id, tenant_id, start_date, end_date, monthly_price la bat buoc'
    });
  }

  // Check phòng đã có hợp đồng active chưa trước khi tạo
  contractService.checkRoomHasActiveContract(room_id, (err, results) => {
    if (err) return res.status(500).json({ success: false, message: 'Loi server', error: err });

    if (results[0].total > 0) {
      return res.status(409).json({
        success: false,
        message: 'Phong nay dang co hop dong hieu luc, khong the tao hop dong moi'
      });
    }

    contractService.createContract(req.body, (err, result) => {
      if (err) return res.status(500).json({ success: false, message: 'Loi server', error: err });
      res.status(201).json({ success: true, message: 'Tao hop dong thanh cong', data: result });
    });
  });
};

const extendContract = (req, res) => {
  const { id } = req.params;
  const { end_date } = req.body;

  if (!end_date) {
    return res.status(400).json({ success: false, message: 'end_date la bat buoc' });
  }

  contractService.extendContract(id, end_date, (err, result) => {
    if (err) return res.status(500).json({ success: false, message: 'Loi server', error: err });
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Khong tim thay hop dong' });
    }
    res.json({ success: true, message: 'Gia han hop dong thanh cong' });
  });
};

const terminateContract = (req, res) => {
  const { id } = req.params;
  contractService.terminateContract(id, (err, result) => {
    if (err) return res.status(500).json({ success: false, message: 'Loi server', error: err });
    if (result.notFound) {
      return res.status(404).json({ success: false, message: 'Khong tim thay hop dong' });
    }
    res.json({ success: true, message: 'Ket thuc hop dong thanh cong' });
  });
};

module.exports = {
  getAllContracts,
  getContractById,
  getContractsByTenant,
  createContract,
  extendContract,
  terminateContract
};