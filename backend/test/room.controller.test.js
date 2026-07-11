const test = require("node:test");
const assert = require("node:assert/strict");

const roomService = require("../src/modules/rooms/room.service");
const roomController = require("../src/modules/rooms/room.controller");

const originalService = { ...roomService };

const createResponse = () => ({
    statusCode: 200,
    body: null,
    status(code) {
        this.statusCode = code;
        return this;
    },
    json(body) {
        this.body = body;
        return this;
    }
});

const validRoomBody = (overrides = {}) => ({
    room_number: "P101",
    room_name: "Phòng tiêu chuẩn P101",
    floor: 0,
    area: 25,
    price: 2500000,
    deposit: 2500000,
    ...overrides
});

test.afterEach(() => {
    Object.assign(roomService, originalService);
});

test("createRoom chuẩn hóa các trường bắt buộc", async () => {
    let receivedPayload;
    roomService.createRoom = async (payload) => {
        receivedPayload = payload;
        return { id: 1, ...payload };
    };

    const req = {
        body: validRoomBody({
            room_number: "  P101  ",
            room_name: "  Phòng tiêu chuẩn P101  "
        })
    };
    const res = createResponse();
    let nextError;

    await roomController.createRoom(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError, undefined);
    assert.equal(res.statusCode, 201);
    assert.deepEqual(receivedPayload, {
        room_number: "P101",
        room_name: "Phòng tiêu chuẩn P101",
        floor: 0,
        area: 25,
        price: 2500000,
        deposit: 2500000,
        status: "available",
        description: null,
        images: []
    });
});

test("listRooms từ chối trạng thái không hợp lệ", async () => {
    const req = { query: { status: "unknown" } };
    const res = createResponse();
    let nextError;

    await roomController.listRooms(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError.statusCode, 400);
    assert.match(nextError.message, /Trạng thái/);
});

test("getRoomDetail từ chối ID không hợp lệ", async () => {
    const req = { params: { id: "abc" } };
    const res = createResponse();
    let nextError;

    await roomController.getRoomDetail(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError.statusCode, 400);
    assert.match(nextError.message, /ID phòng/);
});

test("updateRoomStatus cập nhật một trạng thái hợp lệ", async () => {
    roomService.updateRoomStatus = async (id, status) => ({ id, status });

    const req = {
        params: { id: "2" },
        body: { status: "maintenance" }
    };
    const res = createResponse();
    let nextError;

    await roomController.updateRoomStatus(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError, undefined);
    assert.equal(res.statusCode, 200);
    assert.deepEqual(res.body.data, { id: 2, status: "maintenance" });
});

test("updateRoom từ chối body không có trường phòng", async () => {
    const req = { params: { id: "1" }, body: { unknown: true } };
    const res = createResponse();
    let nextError;

    await roomController.updateRoom(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError.statusCode, 400);
    assert.match(nextError.message, /Không có trường nào/);
});

test("listRooms chuyển bộ lọc trạng thái xuống service", async () => {
    let receivedFilter;
    roomService.getRooms = async (filter) => {
        receivedFilter = filter;
        return [{ id: 3, status: "available" }];
    };

    const req = { query: { status: "available" } };
    const res = createResponse();
    let nextError;

    await roomController.listRooms(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError, undefined);
    assert.deepEqual(receivedFilter, { status: "available" });
    assert.equal(res.body.data.length, 1);
});

test("getRoomDetail trả về 404 khi phòng không tồn tại", async () => {
    roomService.getRoomById = async () => null;

    const req = { params: { id: "99" } };
    const res = createResponse();
    let nextError;

    await roomController.getRoomDetail(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError.statusCode, 404);
});

test("updateRoom chuẩn hóa các trường cần cập nhật", async () => {
    let receivedId;
    let receivedChanges;
    roomService.updateRoom = async (id, changes) => {
        receivedId = id;
        receivedChanges = changes;
        return { id, ...changes };
    };

    const req = {
        params: { id: "4" },
        body: { room_number: " B202 ", price: "4200000" }
    };
    const res = createResponse();
    let nextError;

    await roomController.updateRoom(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError, undefined);
    assert.equal(receivedId, 4);
    assert.deepEqual(receivedChanges, {
        room_number: "B202",
        price: 4200000
    });
});

test("deleteRoom xóa phòng tồn tại", async () => {
    let receivedId;
    roomService.deleteRoom = async (id) => {
        receivedId = id;
        return true;
    };

    const req = { params: { id: "5" } };
    const res = createResponse();
    let nextError;

    await roomController.deleteRoom(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError, undefined);
    assert.equal(receivedId, 5);
    assert.equal(res.body.success, true);
});

test("createRoom nhận tên phòng và loại bỏ URL ảnh trùng lặp", async () => {
    let receivedPayload;
    roomService.createRoom = async (payload) => {
        receivedPayload = payload;
        return { id: 8, ...payload };
    };

    const req = {
        body: {
            ...validRoomBody({
                room_number: "P401",
                room_name: " Phòng sân thượng P401 "
            }),
            images: [
                "https://example.com/room.jpg",
                "https://example.com/room.jpg",
                "https://example.com/detail.jpg"
            ]
        }
    };
    const res = createResponse();
    let nextError;

    await roomController.createRoom(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError, undefined);
    assert.equal(receivedPayload.room_name, "Phòng sân thượng P401");
    assert.deepEqual(receivedPayload.images, [
        "https://example.com/room.jpg",
        "https://example.com/detail.jpg"
    ]);
});

test("createRoom từ chối URL ảnh không hợp lệ", async () => {
    const req = {
        body: {
            ...validRoomBody({
                room_number: "P402",
                room_name: "Phòng P402"
            }),
            images: ["not-an-url"]
        }
    };
    const res = createResponse();
    let nextError;

    await roomController.createRoom(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError.statusCode, 400);
    assert.match(nextError.message, /URL ảnh/);
});

test("createRoom từ chối mã hoặc tên chỉ chứa khoảng trắng", async () => {
    for (const body of [
        validRoomBody({ room_number: "   " }),
        validRoomBody({ room_name: "   " })
    ]) {
        const req = { body };
        const res = createResponse();
        let nextError;
        await roomController.createRoom(req, res, (error) => {
            nextError = error;
        });
        assert.equal(nextError.statusCode, 400);
    }
});

test("createRoom bắt buộc diện tích, giá và tiền cọc lớn hơn 0", async () => {
    for (const field of ["area", "price", "deposit"]) {
        const req = { body: validRoomBody({ [field]: 0 }) };
        const res = createResponse();
        let nextError;
        await roomController.createRoom(req, res, (error) => {
            nextError = error;
        });
        assert.equal(nextError.statusCode, 400);
        assert.match(nextError.message, /lớn hơn 0/);
    }
});
