const crypto = require("node:crypto");
const fs = require("node:fs/promises");
const path = require("node:path");
const multer = require("multer");

const MAX_ROOM_IMAGE_SIZE = 5 * 1024 * 1024;
const ROOM_UPLOAD_DIRECTORY = path.join(
    __dirname,
    "..",
    "..",
    "..",
    "uploads",
    "rooms"
);

const createUploadError = (statusCode, message) => {
    const error = new Error(message);
    error.statusCode = statusCode;
    return error;
};

const hasBytes = (buffer, bytes, offset = 0) =>
    bytes.every((byte, index) => buffer[offset + index] === byte);

const detectImageExtension = (buffer) => {
    if (!Buffer.isBuffer(buffer)) return null;

    if (buffer.length >= 3 && hasBytes(buffer, [0xff, 0xd8, 0xff])) {
        return "jpg";
    }
    if (
        buffer.length >= 8 &&
        hasBytes(buffer, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
    ) {
        return "png";
    }
    if (buffer.length >= 6) {
        const signature = buffer.subarray(0, 6).toString("ascii");
        if (signature === "GIF87a" || signature === "GIF89a") return "gif";
    }
    if (
        buffer.length >= 12 &&
        buffer.subarray(0, 4).toString("ascii") === "RIFF" &&
        buffer.subarray(8, 12).toString("ascii") === "WEBP"
    ) {
        return "webp";
    }
    if (
        buffer.length >= 16 &&
        buffer.subarray(4, 8).toString("ascii") === "ftyp"
    ) {
        const brands = buffer
            .subarray(8, Math.min(buffer.length, 40))
            .toString("ascii");
        if (brands.includes("avif") || brands.includes("avis")) return "avif";
    }

    return null;
};

const uploadRoomImageFile = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: MAX_ROOM_IMAGE_SIZE,
        files: 1,
        fields: 0,
        parts: 2
    }
}).single("image");

const saveRoomImage = async (buffer) => {
    if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
        throw createUploadError(400, "Tệp ảnh không được để trống.");
    }
    if (buffer.length > MAX_ROOM_IMAGE_SIZE) {
        throw createUploadError(413, "Mỗi ảnh không được vượt quá 5 MB.");
    }

    const extension = detectImageExtension(buffer);
    if (!extension) {
        throw createUploadError(
            400,
            "Chỉ nhận ảnh JPG, JPEG, PNG, WEBP, GIF hoặc AVIF hợp lệ."
        );
    }

    await fs.mkdir(ROOM_UPLOAD_DIRECTORY, { recursive: true });
    const fileName = `${Date.now()}-${crypto.randomUUID()}.${extension}`;
    await fs.writeFile(path.join(ROOM_UPLOAD_DIRECTORY, fileName), buffer, {
        flag: "wx"
    });

    return `/uploads/rooms/${fileName}`;
};

module.exports = {
    MAX_ROOM_IMAGE_SIZE,
    ROOM_UPLOAD_DIRECTORY,
    detectImageExtension,
    uploadRoomImageFile,
    saveRoomImage
};
