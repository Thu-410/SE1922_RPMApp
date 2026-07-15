const errorMiddleware = (error, req, res, next) => {
    if (res.headersSent) {
        return next(error);
    }

    let statusCode = error.statusCode || 500;
    let message = error.message || "Lỗi máy chủ nội bộ.";

    if (error.code === "LIMIT_FILE_SIZE") {
        statusCode = 413;
        message = "Mỗi ảnh không được vượt quá 5 MB.";
    } else if (typeof error.code === "string" && error.code.startsWith("LIMIT_")) {
        statusCode = 400;
        message = "Yêu cầu tải ảnh không hợp lệ.";
    } else if (error.code === "ER_DUP_ENTRY") {
        statusCode = 409;
        message = "Số phòng đã tồn tại.";
    } else if (error.code === "ER_ROW_IS_REFERENCED_2") {
        statusCode = 409;
        message = "Không thể xóa phòng đang có dữ liệu liên quan.";
    }

    if (statusCode >= 500) {
        console.error(error);
        message = "Lỗi máy chủ nội bộ.";
    }

    return res.status(statusCode).json({
        success: false,
        message
    });
};

module.exports = errorMiddleware;
