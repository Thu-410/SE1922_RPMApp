const { pool } = require("../src/config/db");

const galleries = {
    P101: [
        "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200",
        "https://images.unsplash.com/photo-1560185008-b033106af5c3?w=1200",
        "https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=1200"
    ],
    P102: [
        "https://images.unsplash.com/photo-1560185007-c5ca9d2c014d?w=1200",
        "https://images.unsplash.com/photo-1560448205-4d9b3e6bb6db?w=1200",
        "https://images.unsplash.com/photo-1554995207-c18c203602cb?w=1200"
    ],
    P201: [
        "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200",
        "https://images.unsplash.com/photo-1564078516393-cf04bd966897?w=1200",
        "https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=1200"
    ],
    P202: [
        "https://images.unsplash.com/photo-1560448075-bb485b067938?w=1200",
        "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=1200"
    ],
    P301: [
        "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1200",
        "https://images.unsplash.com/photo-1560185127-6ed189bf02f4?w=1200",
        "https://images.unsplash.com/photo-1615874694520-474822394e73?w=1200"
    ]
};

const roomDetails = {
    P101: {
        name: "Phòng tiêu chuẩn P101",
        description:
            "Phòng tầng 1 thoáng mát, có cửa sổ lớn, gần cổng và khu để xe. Không gian phù hợp cho 1-2 người ở, khu bếp gọn gàng và đầy đủ ánh sáng tự nhiên."
    },
    P102: {
        name: "Phòng gác lửng P102",
        description:
            "Phòng có gác lửng rộng, khu bếp riêng và cửa sổ lớn. Thiết kế tối ưu diện tích, phù hợp cho người đi làm hoặc sinh viên ở ghép."
    },
    P201: {
        name: "Phòng ban công P201",
        description:
            "Phòng trống sạch sẽ ở tầng 2, có ban công riêng và không gian sinh hoạt rộng. Phù hợp cho gia đình nhỏ hoặc hai người đi làm."
    },
    P202: {
        name: "Phòng tiện nghi P202",
        description:
            "Phòng đang sửa lại nhà vệ sinh, thay hệ thống đèn và kiểm tra đường điện nước. Sau khi hoàn thành sẽ có đầy đủ tiện nghi cơ bản."
    },
    P301: {
        name: "Phòng cao cấp P301",
        description:
            "Phòng diện tích lớn ở tầng 3, nhiều ánh sáng và có khu sinh hoạt riêng. Hiện tạm ngừng sử dụng để nâng cấp nội thất và thiết bị."
    }
};

const run = async () => {
    try {
        for (const [roomNumber, images] of Object.entries(galleries)) {
            const [rooms] = await pool.execute(
                "SELECT id FROM rooms WHERE room_number = ? LIMIT 1",
                [roomNumber]
            );
            if (!rooms[0]) continue;

            const roomId = rooms[0].id;
            const detail = roomDetails[roomNumber];
            await pool.execute(
                `UPDATE rooms
                 SET room_name = CASE
                       WHEN room_name = CONCAT('Phòng ', room_number) THEN ?
                       ELSE room_name
                     END,
                     description = CASE
                       WHEN description IS NULL OR CHAR_LENGTH(description) < 60 THEN ?
                       ELSE description
                     END
                 WHERE id = ?`,
                [detail.name, detail.description, roomId]
            );

            const [countRows] = await pool.execute(
                "SELECT COUNT(*) AS total FROM room_images WHERE room_id = ?",
                [roomId]
            );
            if (countRows[0].total > 0) continue;

            const placeholders = images.map(() => "(?, ?, ?)").join(", ");
            const values = images.flatMap((imageUrl, index) => [roomId, imageUrl, index]);
            await pool.execute(
                `INSERT INTO room_images (room_id, image_url, sort_order)
                 VALUES ${placeholders}`,
                values
            );
            await pool.execute(
                "UPDATE rooms SET image_url = ? WHERE id = ?",
                [images[0], roomId]
            );
        }
        console.log("Đã bổ sung thư viện ảnh mẫu cho các phòng chưa có ảnh.");
    } finally {
        await pool.end();
    }
};

run().catch((error) => {
    console.error("Không thể tạo ảnh mẫu:", error.message);
    process.exitCode = 1;
});
