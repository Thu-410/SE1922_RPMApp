const test = require("node:test");
const assert = require("node:assert/strict");

const {
    ROOM_ACTIONS,
    ROOM_ROLE_POLICY,
    authorizeRoomAction
} = require("../src/modules/rooms/room.authorization");

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

test("module phòng vẫn chạy độc lập khi auth chưa được merge", async () => {
    const error = await check(ROOM_ACTIONS.CREATE, undefined);
    assert.equal(error, undefined);
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

test("strict mode yêu cầu đăng nhập khi không có req.user", async () => {
    const previous = process.env.ROOM_AUTH_REQUIRED;
    process.env.ROOM_AUTH_REQUIRED = "true";
    try {
        const error = await check(ROOM_ACTIONS.LIST, undefined);
        assert.equal(error.statusCode, 401);
    } finally {
        if (previous === undefined) delete process.env.ROOM_AUTH_REQUIRED;
        else process.env.ROOM_AUTH_REQUIRED = previous;
    }
});
