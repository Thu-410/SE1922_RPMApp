const { pool } = require("../src/config/db");

const run = async () => {
    try {
        const [rooms] = await pool.execute(
            "SELECT id, room_number, room_name FROM rooms ORDER BY id"
        );
        let repaired = 0;

        for (const room of rooms) {
            const codeAtEnd = room.room_name?.match(/([A-Za-z]+\d+)$/)?.[1];
            if (!codeAtEnd || codeAtEnd === room.room_number) continue;

            const roomName = room.room_name.replace(
                new RegExp(`${codeAtEnd}$`),
                room.room_number
            );
            await pool.execute(
                "UPDATE rooms SET room_name = ? WHERE id = ?",
                [roomName, room.id]
            );
            repaired += 1;
            console.log(`${codeAtEnd} -> ${room.room_number}: ${roomName}`);
        }

        console.log(`Đã đồng bộ tên cho ${repaired} phòng.`);
    } finally {
        await pool.end();
    }
};

run().catch((error) => {
    console.error("Không thể đồng bộ tên phòng:", error.message);
    process.exitCode = 1;
});
