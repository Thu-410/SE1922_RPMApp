const express = require("express");
const { authenticate } = require("../../middlewares/auth.middleware");
const { requireRoles } = require("../../middlewares/role.middleware");
const userController = require("./user.controller");

const router = express.Router();

router.use(authenticate);
router.get("/me", userController.getMe);
router.get("/", requireRoles("manager"), userController.listUsers);

module.exports = router;
