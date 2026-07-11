const app = require("../server");
const { pool } = require("../src/config/db");

const assert = (condition, message) => {
    if (!condition) throw new Error(message);
};

const run = async () => {
    const server = app.listen(0, "127.0.0.1");
    await new Promise((resolve, reject) => {
        server.once("listening", resolve);
        server.once("error", reject);
    });

    const baseUrl = `http://127.0.0.1:${server.address().port}/api/rooms`;
    const roomNumber = `TEST-${Date.now()}`;
    let roomId;

    const request = async (path = "", options = {}) => {
        const response = await fetch(`${baseUrl}${path}`, {
            ...options,
            headers: { "Content-Type": "application/json", ...options.headers }
        });
        const body = await response.json();
        if (!response.ok) throw new Error(`${response.status}: ${body.message}`);
        return body;
    };

    try {
        const created = await request("", {
            method: "POST",
            body: JSON.stringify({
                room_number: roomNumber,
                room_name: `Phòng kiểm thử ${roomNumber}`,
                floor: 4,
                area: 32.5,
                price: 4100000,
                deposit: 4100000,
                status: "available",
                description: "Phòng dùng để kiểm thử tự động và sẽ được xóa ngay.",
                images: [
                    "https://example.com/room-main.jpg",
                    "https://example.com/room-detail.jpg"
                ]
            })
        });
        roomId = created.data.id;
        assert(created.data.images.length === 2, "Tạo phòng chưa lưu đủ ảnh.");

        const duplicateResponse = await fetch(baseUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                room_number: roomNumber,
                room_name: "Phòng trùng mã",
                floor: 0,
                area: 20,
                price: 2000000,
                deposit: 2000000,
                status: "available"
            })
        });
        assert(
            duplicateResponse.status === 409,
            "Backend chưa chặn mã phòng trùng."
        );

        await pool.execute(
            `INSERT INTO utility_readings
                (room_id, month, year, note)
             VALUES (?, 1, 2099, ?)`,
            [roomId, `Dữ liệu của Phòng kiểm thử ${roomNumber}`]
        );

        const detail = await request(`/${roomId}`);
        assert(detail.data.room_name, "Chi tiết phòng thiếu tên phòng.");
        assert(detail.data.images.length === 2, "Chi tiết phòng thiếu ảnh.");

        const updated = await request(`/${roomId}`, {
            method: "PUT",
            body: JSON.stringify({
                room_number: `${roomNumber}-EDIT`,
                price: 4300000,
                area: 34,
                floor: 5,
                description: "Mô tả đã được cập nhật qua PUT."
            })
        });
        assert(
            updated.data.room_number === `${roomNumber}-EDIT`,
            "Cập nhật mã phòng thất bại."
        );
        assert(
            updated.data.room_name === `Phòng kiểm thử ${roomNumber}-EDIT`,
            "Tên phòng không tự đồng bộ theo mã mới."
        );
        assert(updated.data.price === 4300000, "Cập nhật giá thuê thất bại.");

        const delayedUpdate = await request(`/${roomId}`, {
            method: "PUT",
            body: JSON.stringify({
                room_number: `${roomNumber}-EDIT`,
                room_name: `Phòng kiểm thử ${roomNumber}`
            })
        });
        assert(
            delayedUpdate.data.room_name === `Phòng kiểm thử ${roomNumber}-EDIT`,
            "Request đến chậm đã ghi đè tên phòng bằng mã cũ."
        );

        const renamed = await request(`/${roomId}`, {
            method: "PUT",
            body: JSON.stringify({ room_name: "Căn hộ kiểm thử mới" })
        });
        assert(
            renamed.data.room_name === "Căn hộ kiểm thử mới",
            "Đổi tên phòng thất bại."
        );

        const [utilityRows] = await pool.execute(
            "SELECT note FROM utility_readings WHERE room_id = ? LIMIT 1",
            [roomId]
        );
        assert(
            utilityRows[0].note.includes("Căn hộ kiểm thử mới") &&
                !utilityRows[0].note.includes("Phòng kiểm thử"),
            `Dữ liệu liên quan chưa đồng bộ: ${utilityRows[0].note}`
        );

        const statusUpdated = await request(`/${roomId}/status`, {
            method: "PUT",
            body: JSON.stringify({ status: "maintenance" })
        });
        assert(
            statusUpdated.data.status === "maintenance",
            "PUT cập nhật trạng thái thất bại."
        );

        const filtered = await request("?status=maintenance");
        assert(
            filtered.data.some((room) => room.id === roomId),
            "Lọc trạng thái không trả về phòng kiểm thử."
        );

        await request(`/${roomId}`, { method: "DELETE" });
        roomId = null;
        console.log("Kiểm tra API phòng end-to-end thành công.");
    } finally {
        if (roomId) {
            await fetch(`${baseUrl}/${roomId}`, { method: "DELETE" }).catch(() => {});
        }
        await new Promise((resolve) => server.close(resolve));
        await pool.end();
    }
};

run().catch((error) => {
    console.error("Kiểm tra API thất bại:", error.message);
    process.exitCode = 1;
});
