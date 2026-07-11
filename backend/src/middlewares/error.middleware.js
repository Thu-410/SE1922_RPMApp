const errorMiddleware = (error, req, res, next) => {
    if (res.headersSent) {
        return next(error);
    }

    let statusCode = error.statusCode || 500;
    let message = error.message || "Lỗi máy chủ nội bộ.";

    if (error.code === "ER_DUP_ENTRY") {
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
