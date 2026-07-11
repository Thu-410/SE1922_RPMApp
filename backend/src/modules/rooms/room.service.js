const { pool } = require("../../config/db");

const ROOM_COLUMNS = [
    "id",
    "room_number",
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
    "floor",
    "area",
    "price",
    "deposit",
    "status",
    "description",
    "image_url"
];

const getRooms = async ({ status } = {}) => {
    let query = `SELECT ${ROOM_COLUMNS} FROM rooms`;
    const params = [];

    if (status) {
        query += " WHERE status = ?";
        params.push(status);
    }

    query += " ORDER BY room_number ASC";

    const [rows] = await pool.execute(query, params);
    return rows;
};

const getRoomById = async (id) => {
    const [rows] = await pool.execute(
        `SELECT ${ROOM_COLUMNS} FROM rooms WHERE id = ? LIMIT 1`,
        [id]
    );

    return rows[0] || null;
};

const createRoom = async (room) => {
    const [result] = await pool.execute(
        `INSERT INTO rooms
            (room_number, floor, area, price, deposit, status, description, image_url)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
            room.room_number,
            room.floor,
            room.area,
            room.price,
            room.deposit,
            room.status,
            room.description,
            room.image_url
        ]
    );

    return getRoomById(result.insertId);
};

const updateRoom = async (id, changes) => {
    const fields = UPDATABLE_FIELDS.filter((field) =>
        Object.prototype.hasOwnProperty.call(changes, field)
    );

    if (fields.length === 0) {
        return getRoomById(id);
    }

    const assignments = fields.map((field) => `${field} = ?`).join(", ");
    const values = fields.map((field) => changes[field]);

    const [result] = await pool.execute(
        `UPDATE rooms SET ${assignments} WHERE id = ?`,
        [...values, id]
    );

    if (result.affectedRows === 0) {
        return null;
    }

    return getRoomById(id);
};

const updateRoomStatus = async (id, status) => {
    return updateRoom(id, { status });
};

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
