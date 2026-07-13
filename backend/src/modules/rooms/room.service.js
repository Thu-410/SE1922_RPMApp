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

const escapeRegExp = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const replaceDelimitedReference = (value, oldValue, newValue) => {
    if (!value || !oldValue || oldValue === newValue) return value;
    const pattern = new RegExp(
        `(?<![\\p{L}\\p{N}])${escapeRegExp(oldValue)}(?![\\p{L}\\p{N}])`,
        "gu"
    );
    return value.replace(pattern, newValue);
};

const createConflict = (message) => {
    const error = new Error(message);
    error.statusCode = 409;
    return error;
};

const validateRoomStatusConsistency = (
    status,
    { hasActiveContract = false, hasActiveTenant = false } = {}
) => {
    const occupied = Boolean(hasActiveContract || hasActiveTenant);
    if (status === "occupied" && !occupied) {
        throw createConflict(
            "Chỉ có thể đánh dấu đang thuê khi phòng có người thuê hoặc hợp đồng đang hoạt động."
        );
    }
    if (["available", "inactive"].includes(status) && occupied) {
        throw createConflict(
            "Không thể chuyển phòng đang có người thuê hoặc hợp đồng hoạt động sang trạng thái này."
        );
    }
};

const ensureRoomStatusConsistency = async (executor, roomId, status) => {
    const [rows] = await executor.execute(
        `SELECT
           EXISTS(
             SELECT 1 FROM contracts
             WHERE room_id = ? AND status = 'active'
           ) AS has_active_contract,
           EXISTS(
             SELECT 1 FROM tenants
             WHERE room_id = ? AND status = 'active'
           ) AS has_active_tenant`,
        [roomId, roomId]
    );
    validateRoomStatusConsistency(status, {
        hasActiveContract: Boolean(rows[0]?.has_active_contract),
        hasActiveTenant: Boolean(rows[0]?.has_active_tenant)
    });
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
    validateRoomStatusConsistency(room.status);
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
            `SELECT id, room_number, room_name, description, status, updated_at
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
                if (knownNumber !== effectiveRoomNumber) {
                    normalized = replaceDelimitedReference(
                        normalized,
                        knownNumber,
                        effectiveRoomNumber
                    );
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
            if (roomNameChanged) {
                description = replaceDelimitedReference(
                    description,
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

        if (
            scalarChanges.status !== undefined &&
            scalarChanges.status !== existingRoom.status
        ) {
            await ensureRoomStatusConsistency(connection, id, scalarChanges.status);
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
    deleteRoom,
    replaceDelimitedReference,
    validateRoomStatusConsistency
};
