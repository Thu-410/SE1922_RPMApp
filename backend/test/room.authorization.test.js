const test = require("node:test");
const assert = require("node:assert/strict");

const {
    ROOM_ACTIONS,
    ROOM_ROLE_POLICY,
    authorizeRoomAction
} = require("../src/modules/rooms/room.authorization");
const authService = require("../src/modules/auth/auth.service");
const { authenticate } = require("../src/middlewares/auth.middleware");

const originalAuthService = { ...authService };

test.afterEach(() => {
    Object.assign(authService, originalAuthService);
});

const check = async (action, user) => {
    let nextError;
    await authorizeRoomAction(action)({ user }, {}, (error) => {
        nextError = error;
    });
    return nextError;
};

test("policy phòng khai báo đủ tất cả hành động", () => {
    assert.deepEqual(Object.keys(ROOM_ROLE_POLICY).sort(), [
        ROOM_ACTIONS.CREATE,
        ROOM_ACTIONS.DELETE,
        ROOM_ACTIONS.DETAIL,
        ROOM_ACTIONS.LIST,
        ROOM_ACTIONS.UPDATE,
        ROOM_ACTIONS.UPDATE_STATUS
    ].sort());
});

test("module phòng từ chối request chưa đăng nhập theo mặc định", async () => {
    const error = await check(ROOM_ACTIONS.CREATE, undefined);
    assert.equal(error.statusCode, 401);
});

test("manager có toàn quyền quản lý phòng", async () => {
    for (const action of Object.values(ROOM_ACTIONS)) {
        const error = await check(action, { role_name: "manager" });
        assert.equal(error, undefined);
    }
});

test("staff được xem và cập nhật trạng thái nhưng không được CRUD phòng", async () => {
    for (const action of [
        ROOM_ACTIONS.LIST,
        ROOM_ACTIONS.DETAIL,
        ROOM_ACTIONS.UPDATE_STATUS
    ]) {
        assert.equal(await check(action, { role: { name: "staff" } }), undefined);
    }

    for (const action of [
        ROOM_ACTIONS.CREATE,
        ROOM_ACTIONS.UPDATE,
        ROOM_ACTIONS.DELETE
    ]) {
        const error = await check(action, { role_name: "staff" });
        assert.equal(error.statusCode, 403);
    }
});

test("tenant chỉ được xem danh sách và chi tiết phòng", async () => {
    assert.equal(await check(ROOM_ACTIONS.LIST, { role: "tenant" }), undefined);
    assert.equal(await check(ROOM_ACTIONS.DETAIL, { role: "tenant" }), undefined);

    for (const action of [
        ROOM_ACTIONS.CREATE,
        ROOM_ACTIONS.UPDATE,
        ROOM_ACTIONS.DELETE,
        ROOM_ACTIONS.UPDATE_STATUS
    ]) {
        const error = await check(action, { role_name: "tenant" });
        assert.equal(error.statusCode, 403);
    }
});

test("role không hợp lệ bị từ chối", async () => {
    const error = await check(ROOM_ACTIONS.LIST, { role_name: "unknown" });
    assert.equal(error.statusCode, 403);
});

test("middleware auth yêu cầu Bearer token", async () => {
    let nextError;
    await authenticate({ get: () => undefined }, {}, (error) => {
        nextError = error;
    });
    assert.equal(nextError.statusCode, 401);
});

test("middleware auth lấy lại role và trạng thái hiện tại từ database", async () => {
    authService.verifyToken = () => ({ id: 3, role_name: "manager" });
    authService.getActiveIdentity = async () => ({ id: 3, role_name: "tenant" });
    const req = { get: () => "Bearer valid-token" };
    let nextError;
    await authenticate(req, {}, (error) => {
        nextError = error;
    });
    assert.equal(nextError, undefined);
    assert.deepEqual(req.user, { id: 3, role_name: "tenant" });
});

test("middleware auth từ chối tài khoản đã bị khóa", async () => {
    authService.verifyToken = () => ({ id: 6, role_name: "tenant" });
    authService.getActiveIdentity = async () => null;
    let nextError;
    await authenticate({ get: () => "Bearer valid-token" }, {}, (error) => {
        nextError = error;
    });
    assert.equal(nextError.statusCode, 401);
});

test("middleware auth không che giấu lỗi database thành lỗi đăng nhập", async () => {
    const databaseError = new Error("database unavailable");
    authService.verifyToken = () => ({ id: 1, role_name: "manager" });
    authService.getActiveIdentity = async () => {
        throw databaseError;
    };
    let nextError;
    await authenticate({ get: () => "Bearer valid-token" }, {}, (error) => {
        nextError = error;
    });
    assert.equal(nextError, databaseError);
});
