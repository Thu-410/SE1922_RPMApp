const express = require("express");
const cors = require("cors");
const { pool, connectDB } = require("./src/config/db");
const roomRoutes = require("./src/modules/rooms/room.route");
const { ensureRoomSoftDeleteSchema } = require("./src/modules/rooms/room.service");
const errorMiddleware = require("./src/middlewares/error.middleware");

const app = express();

const configuredOrigins = new Set(
    (process.env.CORS_ORIGINS || "")
        .split(",")
        .map((origin) => origin.trim())
        .filter(Boolean)
);
const isDevelopmentOrigin = (origin) =>
    process.env.NODE_ENV !== "production" &&
    /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);

app.use(
    cors({
        origin(origin, callback) {
            const allowed =
                !origin || configuredOrigins.has(origin) || isDevelopmentOrigin(origin);
            callback(null, allowed);
        }
    })
);
app.use(express.json({ limit: "100kb" }));

app.get("/health", async (req, res, next) => {
    try {
        await pool.query("SELECT 1");
        res.json({ success: true });
    } catch (error) {
        next(error);
    }
});

app.use("/api/rooms", roomRoutes);

app.use((req, res) => {
    res.status(404).json({ success: false, message: "Không tìm thấy API." });
});

app.use(errorMiddleware);

const startServer = async () => {
    const port = Number(process.env.PORT) || 3000;

    await connectDB();
    await ensureRoomSoftDeleteSchema();
    app.listen(port, () => {
        console.log(`Ứng dụng đang chạy ở cổng ${port}`);
    });
};

if (require.main === module) {
    startServer().catch((error) => {
        console.error("Không thể khởi động ứng dụng:", error.message);
        process.exitCode = 1;
    });
}

module.exports = app;
