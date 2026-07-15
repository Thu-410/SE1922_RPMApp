const test = require("node:test");
const assert = require("node:assert/strict");

const { pool } = require("../src/config/db");
const roomService = require("../src/modules/rooms/room.service");
const roomController = require("../src/modules/rooms/room.controller");

const originalService = { ...roomService };
const originalPool = {
    execute: pool.execute,
    getConnection: pool.getConnection
};

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
    pool.execute = originalPool.execute;
    pool.getConnection = originalPool.getConnection;
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
    let receivedVersion;
    roomService.updateRoomStatus = async (id, status, expectedVersion) => {
        receivedVersion = expectedVersion;
        return { id, status };
    };

    const req = {
        params: { id: "2" },
        body: { status: "maintenance", expected_version: 4 }
    };
    const res = createResponse();
    let nextError;

    await roomController.updateRoomStatus(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError, undefined);
    assert.equal(res.statusCode, 200);
    assert.equal(receivedVersion, 4);
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

test("updateRoom từ chối request chỉ có phiên bản nhưng không có thay đổi", async () => {
    const req = { params: { id: "1" }, body: { expected_version: 2 } };
    const res = createResponse();
    let nextError;

    await roomController.updateRoom(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError.statusCode, 400);
    assert.match(nextError.message, /Không có trường nào/);
});

test("updateRoom yêu cầu phiên bản để chống ghi đè dữ liệu", async () => {
    const req = { params: { id: "1" }, body: { price: 3000000 } };
    const res = createResponse();
    let nextError;

    await roomController.updateRoom(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError.statusCode, 428);
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
        body: {
            room_number: " B202 ",
            price: "4200000",
            expected_version: 7
        }
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
        price: 4200000,
        expected_version: 7
    });
});

test("deleteRoom xóa mềm phòng tồn tại", async () => {
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

test("createRoom chấp nhận đường dẫn ảnh do backend đã upload", async () => {
    let receivedPayload;
    roomService.createRoom = async (payload) => {
        receivedPayload = payload;
        return { id: 10, ...payload };
    };

    const req = {
        body: {
            ...validRoomBody({ room_number: "P403", room_name: "Phòng P403" }),
            images: ["/uploads/rooms/123-test-id.png"]
        }
    };
    const res = createResponse();
    let nextError;

    await roomController.createRoom(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError, undefined);
    assert.deepEqual(receivedPayload.images, ["/uploads/rooms/123-test-id.png"]);
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

test("đổi mã phòng không thay nhầm mã dài hơn", () => {
    assert.equal(
        roomService.replaceDelimitedReference(
            "Phòng P1 chuyển từ khu P10 sang dãy P1.",
            "P1",
            "P2"
        ),
        "Phòng P2 chuyển từ khu P10 sang dãy P2."
    );
});

test("createRoom cho phép chọn trạng thái đang thuê", async () => {
    let receivedStatus;
    roomService.createRoom = async (payload) => {
        receivedStatus = payload.status;
        return { id: 9, ...payload };
    };

    const req = { body: validRoomBody({ status: "occupied" }) };
    const res = createResponse();
    let nextError;

    await roomController.createRoom(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError, undefined);
    assert.equal(res.statusCode, 201);
    assert.equal(receivedStatus, "occupied");
});

test("không cho client tự tạo phòng ở trạng thái deleted", async () => {
    const req = { body: validRoomBody({ status: "deleted" }) };
    const res = createResponse();
    let nextError;

    await roomController.createRoom(req, res, (error) => {
        nextError = error;
    });

    assert.equal(nextError.statusCode, 400);
    assert.match(nextError.message, /Trạng thái/);
});

test("updateRoomStatus chấp nhận đầy đủ các trạng thái phòng", async () => {
    const receivedStatuses = [];
    roomService.updateRoomStatus = async (id, status) => {
        receivedStatuses.push(status);
        return { id, status };
    };

    for (const status of ["available", "occupied", "maintenance", "inactive"]) {
        const req = {
            params: { id: "2" },
            body: { status, expected_version: 1 }
        };
        const res = createResponse();
        let nextError;
        await roomController.updateRoomStatus(req, res, (error) => {
            nextError = error;
        });
        assert.equal(nextError, undefined);
        assert.equal(res.body.data.status, status);
    }

    assert.deepEqual(receivedStatuses, [
        "available",
        "occupied",
        "maintenance",
        "inactive"
    ]);
});

test("room service lọc trạng thái bằng truy vấn có tham số", async () => {
    const calls = [];
    pool.execute = async (sql, params = []) => {
        calls.push({ sql, params });
        if (sql.includes("FROM rooms")) {
            return [[{
                id: 5,
                room_number: "P301",
                room_name: "Phòng P301",
                floor: 3,
                area: 30,
                price: 3000000,
                deposit: 3000000,
                status: "inactive",
                version: 2,
                description: null,
                image_url: null,
                created_at: new Date(),
                updated_at: new Date()
            }]];
        }
        if (sql.includes("FROM room_images")) return [[]];
        throw new Error(`Truy vấn không mong đợi: ${sql}`);
    };

    const rooms = await originalService.getRooms({ status: "inactive" });

    assert.equal(rooms.length, 1);
    assert.equal(rooms[0].status, "inactive");
    assert.match(calls[0].sql, /WHERE status <> 'deleted' AND status = \?/);
    assert.deepEqual(calls[0].params, ["inactive"]);
});

test("room service tạo phòng đang thuê và lưu ảnh trong transaction", async () => {
    const connectionCalls = [];
    let committed = false;
    let released = false;
    const connection = {
        async beginTransaction() {},
        async execute(sql, params = []) {
            connectionCalls.push({ sql, params });
            if (sql.includes("INSERT INTO rooms")) return [{ insertId: 12 }];
            if (sql.includes("INSERT INTO room_images")) return [{ affectedRows: 1 }];
            throw new Error(`Truy vấn không mong đợi: ${sql}`);
        },
        async commit() {
            committed = true;
        },
        async rollback() {},
        release() {
            released = true;
        }
    };
    pool.getConnection = async () => connection;
    pool.execute = async (sql) => {
        if (sql.includes("FROM rooms") && sql.includes("WHERE id = ?")) {
            return [[{
                id: 12,
                room_number: "P501",
                room_name: "Phòng P501",
                floor: 5,
                area: 28,
                price: 2800000,
                deposit: 2800000,
                status: "occupied",
                version: 1,
                description: null,
                image_url: "https://example.com/p501.jpg",
                created_at: new Date(),
                updated_at: new Date()
            }]];
        }
        if (sql.includes("FROM room_images")) {
            return [[{
                room_id: 12,
                image_url: "https://example.com/p501.jpg"
            }]];
        }
        throw new Error(`Truy vấn không mong đợi: ${sql}`);
    };

    const room = await originalService.createRoom({
        room_number: "P501",
        room_name: "Phòng P501",
        floor: 5,
        area: 28,
        price: 2800000,
        deposit: 2800000,
        status: "occupied",
        description: null,
        images: ["https://example.com/p501.jpg"]
    });

    assert.equal(room.status, "occupied");
    assert.equal(committed, true);
    assert.equal(released, true);
    assert.equal(connectionCalls.some(({ sql }) => /tenants|contracts/.test(sql)), false);
    assert.equal(connectionCalls.some(({ sql }) => sql.includes("room_images")), true);
});

test("room service cập nhật trạng thái bằng version và không phụ thuộc module khác", async () => {
    const calls = [];
    let committed = false;
    const connection = {
        async beginTransaction() {},
        async execute(sql, params = []) {
            calls.push({ sql, params });
            if (sql.includes("FROM rooms") && sql.includes("FOR UPDATE")) {
                return [[{
                    id: 2,
                    room_number: "P102",
                    room_name: "Phòng P102",
                    description: null,
                    status: "available",
                    version: 3,
                    updated_at: new Date()
                }]];
            }
            if (sql.includes("FROM room_number_history")) return [[]];
            if (sql.includes("UPDATE rooms")) return [{ affectedRows: 1 }];
            throw new Error(`Truy vấn không mong đợi: ${sql}`);
        },
        async commit() {
            committed = true;
        },
        async rollback() {},
        release() {}
    };
    pool.getConnection = async () => connection;
    pool.execute = async (sql) => {
        if (sql.includes("FROM rooms") && sql.includes("WHERE id = ?")) {
            return [[{
                id: 2,
                room_number: "P102",
                room_name: "Phòng P102",
                floor: 1,
                area: 20,
                price: 2000000,
                deposit: 2000000,
                status: "occupied",
                version: 4,
                description: null,
                image_url: null,
                created_at: new Date(),
                updated_at: new Date()
            }]];
        }
        if (sql.includes("FROM room_images")) return [[]];
        throw new Error(`Truy vấn không mong đợi: ${sql}`);
    };

    const room = await originalService.updateRoomStatus(2, "occupied", 3);

    assert.equal(room.status, "occupied");
    assert.equal(room.version, 4);
    assert.equal(committed, true);
    assert.equal(calls.some(({ sql }) => /tenants|contracts/.test(sql)), false);
    const updateCall = calls.find(({ sql }) => sql.includes("UPDATE rooms"));
    assert.deepEqual(updateCall.params, ["occupied", 2]);
});

test("room service không cho xóa phòng đang thuê", async () => {
    let rolledBack = false;
    let updated = false;
    const connection = {
        async beginTransaction() {},
        async execute(sql) {
            if (sql.includes("SELECT id, status")) {
                return [[{ id: 1, status: "occupied" }]];
            }
            if (sql.includes("UPDATE rooms")) {
                updated = true;
                return [{ affectedRows: 1 }];
            }
            throw new Error(`Truy vấn không mong đợi: ${sql}`);
        },
        async commit() {},
        async rollback() {
            rolledBack = true;
        },
        release() {}
    };
    pool.getConnection = async () => connection;

    await assert.rejects(
        () => originalService.deleteRoom(1),
        (error) => error.statusCode === 409 && /đang thuê/.test(error.message)
    );
    assert.equal(rolledBack, true);
    assert.equal(updated, false);
});

test("room service xóa mềm phòng không thuê bằng trạng thái deleted", async () => {
    const calls = [];
    let committed = false;
    const connection = {
        async beginTransaction() {},
        async execute(sql, params = []) {
            calls.push({ sql, params });
            if (sql.includes("SELECT id, status")) {
                return [[{ id: 4, status: "maintenance" }]];
            }
            if (sql.includes("UPDATE rooms")) return [{ affectedRows: 1 }];
            throw new Error(`Truy vấn không mong đợi: ${sql}`);
        },
        async commit() {
            committed = true;
        },
        async rollback() {},
        release() {}
    };
    pool.getConnection = async () => connection;

    const deleted = await originalService.deleteRoom(4);

    assert.equal(deleted, true);
    assert.equal(committed, true);
    const updateCall = calls.find(({ sql }) => sql.includes("UPDATE rooms"));
    assert.match(updateCall.sql, /SET status = 'deleted'/);
    assert.deepEqual(updateCall.params, [4]);
    assert.equal(calls.some(({ sql }) => sql.startsWith("DELETE FROM rooms")), false);
});

test("room service tự bổ sung trạng thái deleted vào schema khi cần", async () => {
    const calls = [];
    pool.execute = async (sql) => {
        calls.push(sql);
        if (sql.includes("information_schema.COLUMNS")) {
            return [[{
                column_type:
                    "enum('available','occupied','maintenance','inactive')"
            }]];
        }
        if (sql.includes("ALTER TABLE rooms")) return [{ affectedRows: 0 }];
        throw new Error(`Truy vấn không mong đợi: ${sql}`);
    };

    await originalService.ensureRoomSoftDeleteSchema();

    assert.equal(calls.length, 2);
    assert.match(calls[1], /'deleted'/);
});
