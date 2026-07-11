const roomService = require("./room.service");

const ROOM_STATUSES = ["available", "occupied", "maintenance", "inactive"];
const ROOM_FIELDS = [
    "room_number",
    "room_name",
    "floor",
    "area",
    "price",
    "deposit",
    "status",
    "description",
    "image_url",
    "images"
];

class HttpError extends Error {
    constructor(statusCode, message) {
        super(message);
        this.statusCode = statusCode;
    }
}

const parseId = (value) => {
    const id = Number(value);

    if (!Number.isInteger(id) || id <= 0) {
        throw new HttpError(400, "ID phòng không hợp lệ.");
    }

    return id;
};

const parseNonNegativeNumber = (value, fieldName) => {
    const number = Number(value);

    if (value === "" || value === null || !Number.isFinite(number) || number < 0) {
        throw new HttpError(400, `${fieldName} phải là số lớn hơn hoặc bằng 0.`);
    }

    return number;
};

const normalizeImages = (value) => {
    if (!Array.isArray(value)) {
        throw new HttpError(400, "Danh sách ảnh phòng phải là một mảng.");
    }
    if (value.length > 10) {
        throw new HttpError(400, "Mỗi phòng được phép có tối đa 10 ảnh.");
    }

    const images = [];
    for (const rawImage of value) {
        if (typeof rawImage !== "string" || !rawImage.trim()) {
            throw new HttpError(400, "Mỗi ảnh phòng phải là một URL hợp lệ.");
        }
        const image = rawImage.trim();
        if (image.length > 500) {
            throw new HttpError(400, "URL ảnh không được vượt quá 500 ký tự.");
        }

        let url;
        try {
            url = new URL(image);
        } catch (_) {
            throw new HttpError(400, "URL ảnh phòng không hợp lệ.");
        }
        if (!["http:", "https:"].includes(url.protocol)) {
            throw new HttpError(400, "URL ảnh phòng phải dùng HTTP hoặc HTTPS.");
        }
        if (!images.includes(image)) images.push(image);
    }
    return images;
};

const normalizeRoomPayload = (body, { partial = false } = {}) => {
    if (!body || typeof body !== "object" || Array.isArray(body)) {
        throw new HttpError(400, "Dữ liệu phòng không hợp lệ.");
    }

    const payload = {};
    const has = (field) => Object.prototype.hasOwnProperty.call(body, field);

    if (!partial || has("room_number")) {
        if (typeof body.room_number !== "string" || !body.room_number.trim()) {
            throw new HttpError(400, "Số phòng là bắt buộc.");
        }

        payload.room_number = body.room_number.trim();
        if (payload.room_number.length > 50) {
            throw new HttpError(400, "Số phòng không được vượt quá 50 ký tự.");
        }
    }

    if (!partial || has("room_name")) {
        const defaultName = payload.room_number
            ? `Phòng ${payload.room_number}`
            : undefined;
        const value = partial ? body.room_name : body.room_name ?? defaultName;
        if (typeof value !== "string" || !value.trim()) {
            throw new HttpError(400, "Tên phòng là bắt buộc.");
        }
        payload.room_name = value.trim();
        if (payload.room_name.length > 150) {
            throw new HttpError(400, "Tên phòng không được vượt quá 150 ký tự.");
        }
    }

    if (!partial || has("floor")) {
        const floor = partial ? Number(body.floor) : Number(body.floor ?? 1);
        if (!Number.isInteger(floor) || floor < 1) {
            throw new HttpError(400, "Tầng phải là số nguyên lớn hơn hoặc bằng 1.");
        }
        payload.floor = floor;
    }

    for (const [field, label, defaultValue] of [
        ["area", "Diện tích", 0],
        ["price", "Giá phòng", 0],
        ["deposit", "Tiền cọc", 0]
    ]) {
        if (!partial || has(field)) {
            payload[field] = parseNonNegativeNumber(
                partial ? body[field] : body[field] ?? defaultValue,
                label
            );
        }
    }

    if (!partial || has("status")) {
        const status = partial ? body.status : body.status ?? "available";
        if (!ROOM_STATUSES.includes(status)) {
            throw new HttpError(
                400,
                `Trạng thái phải là một trong các giá trị: ${ROOM_STATUSES.join(", ")}.`
            );
        }
        payload.status = status;
    }

    for (const field of ["description"]) {
        if (!partial || has(field)) {
            const value = partial ? body[field] : body[field] ?? null;
            if (value !== null && typeof value !== "string") {
                throw new HttpError(400, `${field} phải là chuỗi hoặc null.`);
            }
            payload[field] = typeof value === "string" ? value.trim() || null : null;
        }
    }

    if (!partial || has("images") || has("image_url")) {
        let rawImages = has("images") ? body.images : [];
        if (!has("images") && typeof body.image_url === "string" && body.image_url.trim()) {
            rawImages = [body.image_url];
        }
        payload.images = normalizeImages(rawImages);
    }

    if (partial && !ROOM_FIELDS.some((field) => has(field))) {
        throw new HttpError(400, "Không có trường nào để cập nhật.");
    }

    return payload;
};

const listRooms = async (req, res, next) => {
    try {
        const status = req.query.status;

        if (status !== undefined && !ROOM_STATUSES.includes(status)) {
            throw new HttpError(
                400,
                `Trạng thái phải là một trong các giá trị: ${ROOM_STATUSES.join(", ")}.`
            );
        }

        const rooms = await roomService.getRooms({ status });
        res.json({ success: true, data: rooms });
    } catch (error) {
        next(error);
    }
};

const getRoomDetail = async (req, res, next) => {
    try {
        const room = await roomService.getRoomById(parseId(req.params.id));

        if (!room) {
            throw new HttpError(404, "Không tìm thấy phòng.");
        }

        res.json({ success: true, data: room });
    } catch (error) {
        next(error);
    }
};

const createRoom = async (req, res, next) => {
    try {
        const room = await roomService.createRoom(normalizeRoomPayload(req.body));
        res.status(201).json({
            success: true,
            message: "Thêm phòng thành công.",
            data: room
        });
    } catch (error) {
        next(error);
    }
};

const updateRoom = async (req, res, next) => {
    try {
        const id = parseId(req.params.id);
        const room = await roomService.updateRoom(
            id,
            normalizeRoomPayload(req.body, { partial: true })
        );

        if (!room) {
            throw new HttpError(404, "Không tìm thấy phòng.");
        }

        res.json({
            success: true,
            message: "Cập nhật phòng thành công.",
            data: room
        });
    } catch (error) {
        next(error);
    }
};

const updateRoomStatus = async (req, res, next) => {
    try {
        const id = parseId(req.params.id);
        const { status } = req.body || {};

        if (!ROOM_STATUSES.includes(status)) {
            throw new HttpError(
                400,
                `Trạng thái phải là một trong các giá trị: ${ROOM_STATUSES.join(", ")}.`
            );
        }

        const room = await roomService.updateRoomStatus(id, status);

        if (!room) {
            throw new HttpError(404, "Không tìm thấy phòng.");
        }

        res.json({
            success: true,
            message: "Cập nhật trạng thái phòng thành công.",
            data: room
        });
    } catch (error) {
        next(error);
    }
};

const deleteRoom = async (req, res, next) => {
    try {
        const deleted = await roomService.deleteRoom(parseId(req.params.id));

        if (!deleted) {
            throw new HttpError(404, "Không tìm thấy phòng.");
        }

        res.json({ success: true, message: "Xóa phòng thành công." });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    listRooms,
    getRoomDetail,
    createRoom,
    updateRoom,
    updateRoomStatus,
    deleteRoom
};
