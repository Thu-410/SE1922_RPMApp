const express = require("express");
const roomController = require("./room.controller");
const {
    ROOM_ACTIONS,
    authorizeRoomAction
} = require("./room.authorization");

const router = express.Router();

router.get("/", authorizeRoomAction(ROOM_ACTIONS.LIST), roomController.listRooms);
router.get(
    "/:id",
    authorizeRoomAction(ROOM_ACTIONS.DETAIL),
    roomController.getRoomDetail
);
router.post(
    "/",
    authorizeRoomAction(ROOM_ACTIONS.CREATE),
    roomController.createRoom
);
router.put(
    "/:id",
    authorizeRoomAction(ROOM_ACTIONS.UPDATE),
    roomController.updateRoom
);
router.put(
    "/:id/status",
    authorizeRoomAction(ROOM_ACTIONS.UPDATE_STATUS),
    roomController.updateRoomStatus
);
// Giữ PATCH để tương thích với các phiên bản frontend cũ.
router.patch(
    "/:id/status",
    authorizeRoomAction(ROOM_ACTIONS.UPDATE_STATUS),
    roomController.updateRoomStatus
);
router.delete(
    "/:id",
    authorizeRoomAction(ROOM_ACTIONS.DELETE),
    roomController.deleteRoom
);

module.exports = router;
