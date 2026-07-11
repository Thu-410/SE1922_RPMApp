const express = require("express");
const roomController = require("./room.controller");

const router = express.Router();

router.get("/", roomController.listRooms);
router.get("/:id", roomController.getRoomDetail);
router.post("/", roomController.createRoom);
router.put("/:id", roomController.updateRoom);
router.patch("/:id/status", roomController.updateRoomStatus);
router.delete("/:id", roomController.deleteRoom);

module.exports = router;
