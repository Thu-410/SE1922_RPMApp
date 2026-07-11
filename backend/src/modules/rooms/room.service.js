const { pool } = require("../../config/db");

const ROOM_COLUMNS = [
    "id",
    "room_number",
    "room_name",
    "floor",
    "area",
    "price",
    "deposit",
    "status",
    "description",
    "image_url",
    "created_at",
    "updated_at"
].join(", ");

const UPDATABLE_FIELDS = [
    "room_number",
    "room_name",
    "floor",
    "area",
    "price",
    "deposit",
    "status",
    "description",
    "image_url"
];

const attachImages = async (executor, rooms) => {
    if (rooms.length === 0) return rooms;

    const placeholders = rooms.map(() => "?").join(", ");
    const [imageRows] = await executor.execute(
        `SELECT room_id, image_url
         FROM room_images
         WHERE room_id IN (${placeholders})
         ORDER BY room_id ASC, sort_order ASC, id ASC`,
        rooms.map((room) => room.id)
    );

    const imagesByRoom = new Map();
    for (const image of imageRows) {
        const images = imagesByRoom.get(image.room_id) || [];
        images.push(image.image_url);
        imagesByRoom.set(image.room_id, images);
    }

    return rooms.map((room) => {
        const images = imagesByRoom.get(room.id) || [];
        if (images.length === 0 && room.image_url) images.push(room.image_url);
        return {
            ...room,
            image_url: images[0] || null,
            images
        };
    });
};

const insertImages = async (executor, roomId, images) => {
    if (!images || images.length === 0) return;

    const placeholders = images.map(() => "(?, ?, ?)").join(", ");
    const values = images.flatMap((imageUrl, index) => [roomId, imageUrl, index]);
    await executor.execute(
        `INSERT INTO room_images (room_id, image_url, sort_order)
         VALUES ${placeholders}`,
        values
    );
};

const replaceRelatedRoomReference = async (
    executor,
    roomId,
    oldRoomNumber,
    newRoomNumber
) => {
    const likeOldNumber = `%${oldRoomNumber}%`;
    const updates = [
        [
            `UPDATE contracts
             SET note = REPLACE(note, ?, ?)
             WHERE room_id = ? AND note LIKE ?`,
            [oldRoomNumber, newRoomNumber, roomId, likeOldNumber]
        ],
        [
            `UPDATE utility_readings
             SET note = REPLACE(note, ?, ?)
             WHERE room_id = ? AND note LIKE ?`,
            [oldRoomNumber, newRoomNumber, roomId, likeOldNumber]
        ],
        [
            `UPDATE invoices
             SET note = REPLACE(note, ?, ?)
             WHERE room_id = ? AND note LIKE ?`,
            [oldRoomNumber, newRoomNumber, roomId, likeOldNumber]
        ],
        [
            `UPDATE invoice_details AS detail
             JOIN invoices AS invoice ON invoice.id = detail.invoice_id
             SET detail.item_name = REPLACE(detail.item_name, ?, ?),
                 detail.note = CASE
                   WHEN detail.note IS NULL THEN NULL
                   ELSE REPLACE(detail.note, ?, ?)
                 END
             WHERE invoice.room_id = ?
               AND (detail.item_name LIKE ? OR detail.note LIKE ?)`,
            [
                oldRoomNumber,
                newRoomNumber,
                oldRoomNumber,
                newRoomNumber,
                roomId,
                likeOldNumber,
                likeOldNumber
            ]
        ],
        [
            `UPDATE payments AS payment
             JOIN invoices AS invoice ON invoice.id = payment.invoice_id
             SET payment.note = REPLACE(payment.note, ?, ?)
             WHERE invoice.room_id = ? AND payment.note LIKE ?`,
            [oldRoomNumber, newRoomNumber, roomId, likeOldNumber]
        ],
        [
            `UPDATE maintenance_requests
             SET title = REPLACE(title, ?, ?),
                 description = REPLACE(description, ?, ?),
                 manager_note = CASE
                   WHEN manager_note IS NULL THEN NULL
                   ELSE REPLACE(manager_note, ?, ?)
                 END
             WHERE room_id = ?
               AND (
                 title LIKE ? OR description LIKE ? OR manager_note LIKE ?
               )`,
            [
                oldRoomNumber,
                newRoomNumber,
                oldRoomNumber,
                newRoomNumber,
                oldRoomNumber,
                newRoomNumber,
                roomId,
                likeOldNumber,
                likeOldNumber,
                likeOldNumber
            ]
        ],
        [
            `UPDATE notifications AS notification
             JOIN invoices AS invoice
               ON notification.related_type = 'invoice'
              AND notification.related_id = invoice.id
             SET notification.title = REPLACE(notification.title, ?, ?),
                 notification.content = REPLACE(notification.content, ?, ?)
             WHERE invoice.room_id = ?
               AND (
                 notification.title LIKE ? OR notification.content LIKE ?
               )`,
            [
                oldRoomNumber,
                newRoomNumber,
                oldRoomNumber,
                newRoomNumber,
                roomId,
                likeOldNumber,
                likeOldNumber
            ]
        ],
        [
            `UPDATE notifications AS notification
             JOIN maintenance_requests AS request
               ON notification.related_type = 'maintenance_request'
              AND notification.related_id = request.id
             SET notification.title = REPLACE(notification.title, ?, ?),
                 notification.content = REPLACE(notification.content, ?, ?)
             WHERE request.room_id = ?
               AND (
                 notification.title LIKE ? OR notification.content LIKE ?
               )`,
            [
                oldRoomNumber,
                newRoomNumber,
                oldRoomNumber,
                newRoomNumber,
                roomId,
                likeOldNumber,
                likeOldNumber
            ]
        ]
    ];

    for (const [query, params] of updates) {
        await executor.execute(query, params);
    }
};

const getRooms = async ({ status } = {}) => {
    let query = `SELECT ${ROOM_COLUMNS} FROM rooms`;
    const params = [];

    if (status) {
        query += " WHERE status = ?";
        params.push(status);
    }

    query += " ORDER BY room_number ASC";
    const [rows] = await pool.execute(query, params);
    return attachImages(pool, rows);
};

const getRoomById = async (id, executor = pool) => {
    const [rows] = await executor.execute(
        `SELECT ${ROOM_COLUMNS} FROM rooms WHERE id = ? LIMIT 1`,
        [id]
    );

    if (!rows[0]) return null;
    const [room] = await attachImages(executor, rows);
    return room;
};

const createRoom = async (room) => {
    const connection = await pool.getConnection();

    try {
        await connection.beginTransaction();
        const [result] = await connection.execute(
            `INSERT INTO rooms
                (room_number, room_name, floor, area, price, deposit, status,
                 description, image_url)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                room.room_number,
                room.room_name,
                room.floor,
                room.area,
                room.price,
                room.deposit,
                room.status,
                room.description,
                room.images[0] || null
            ]
        );

        await insertImages(connection, result.insertId, room.images);
        await connection.commit();
        return getRoomById(result.insertId);
    } catch (error) {
        await connection.rollback();
        throw error;
    } finally {
        connection.release();
    }
};

const updateRoom = async (id, changes) => {
    const connection = await pool.getConnection();

    try {
        await connection.beginTransaction();
        const [existingRows] = await connection.execute(
            `SELECT id, room_number, room_name, description, updated_at
             FROM rooms
             WHERE id = ?
             FOR UPDATE`,
            [id]
        );

        if (!existingRows[0]) {
            await connection.rollback();
            return null;
        }

        const existingRoom = existingRows[0];
        const scalarChanges = { ...changes };
        delete scalarChanges.images;
        delete scalarChanges.expected_updated_at;

        if (changes.expected_updated_at) {
            const expectedTime = new Date(changes.expected_updated_at).getTime();
            const currentTime = new Date(existingRoom.updated_at).getTime();
            if (expectedTime !== currentTime) {
                const conflict = new Error(
                    "Phòng đã được cập nhật ở màn hình khác. Vui lòng tải lại dữ liệu."
                );
                conflict.statusCode = 409;
                throw conflict;
            }
        }

        const [historyRows] = await connection.execute(
            `SELECT room_number
             FROM room_number_history
             WHERE room_id = ?`,
            [id]
        );
        const knownRoomNumbers = [
            existingRoom.room_number,
            ...historyRows.map((row) => row.room_number)
        ].sort((left, right) => right.length - left.length);

        const effectiveRoomNumber =
            scalarChanges.room_number ?? existingRoom.room_number;
        const roomNumberChanged =
            effectiveRoomNumber !== existingRoom.room_number;

        const replaceKnownRoomNumbers = (value) => {
            let normalized = value;
            for (const knownNumber of knownRoomNumbers) {
                if (knownNumber !== effectiveRoomNumber && normalized?.includes(knownNumber)) {
                    normalized = normalized.replaceAll(knownNumber, effectiveRoomNumber);
                }
            }
            return normalized;
        };

        if (roomNumberChanged || scalarChanges.room_name !== undefined) {
            scalarChanges.room_name = replaceKnownRoomNumbers(
                scalarChanges.room_name ?? existingRoom.room_name
            );
        }

        const effectiveRoomName =
            scalarChanges.room_name ?? existingRoom.room_name;
        const roomNameChanged = effectiveRoomName !== existingRoom.room_name;

        if (
            roomNumberChanged ||
            roomNameChanged ||
            scalarChanges.description !== undefined
        ) {
            let description = scalarChanges.description ?? existingRoom.description;
            if (roomNameChanged && description?.includes(existingRoom.room_name)) {
                description = description.replaceAll(
                    existingRoom.room_name,
                    effectiveRoomName
                );
            }
            scalarChanges.description = replaceKnownRoomNumbers(description);
        }

        if (Object.prototype.hasOwnProperty.call(changes, "images")) {
            scalarChanges.image_url = changes.images[0] || null;
        }

        if (roomNumberChanged) {
            await connection.execute(
                `INSERT IGNORE INTO room_number_history (room_id, room_number)
                 VALUES (?, ?)`,
                [id, existingRoom.room_number]
            );
        }

        const fields = UPDATABLE_FIELDS.filter((field) =>
            Object.prototype.hasOwnProperty.call(scalarChanges, field)
        );

        if (fields.length > 0) {
            const assignments = fields.map((field) => `${field} = ?`).join(", ");
            const values = fields.map((field) => scalarChanges[field]);
            await connection.execute(
                `UPDATE rooms SET ${assignments} WHERE id = ?`,
                [...values, id]
            );
        }

        if (Object.prototype.hasOwnProperty.call(changes, "images")) {
            await connection.execute("DELETE FROM room_images WHERE room_id = ?", [id]);
            await insertImages(connection, id, changes.images);
        }

        if (roomNameChanged) {
            await replaceRelatedRoomReference(
                connection,
                id,
                existingRoom.room_name,
                effectiveRoomName
            );
        }

        if (roomNumberChanged) {
            for (const knownRoomNumber of knownRoomNumbers) {
                if (knownRoomNumber === effectiveRoomNumber) continue;
                await replaceRelatedRoomReference(
                    connection,
                    id,
                    knownRoomNumber,
                    effectiveRoomNumber
                );
            }
        }

        await connection.commit();
        return getRoomById(id);
    } catch (error) {
        await connection.rollback();
        throw error;
    } finally {
        connection.release();
    }
};

const updateRoomStatus = async (id, status) => updateRoom(id, { status });

const deleteRoom = async (id) => {
    const [result] = await pool.execute("DELETE FROM rooms WHERE id = ?", [id]);
    return result.affectedRows > 0;
};

module.exports = {
    getRooms,
    getRoomById,
    createRoom,
    updateRoom,
    updateRoomStatus,
    deleteRoom
};
