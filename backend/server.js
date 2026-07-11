const express = require("express");
const cors = require("cors");
const { pool, connectDB } = require("./src/config/db");
const roomRoutes = require("./src/modules/rooms/room.route");
const errorMiddleware = require("./src/middlewares/error.middleware");

const app = express();

app.use(cors());
app.use(express.json());

// Giữ lại endpoint hiện tại để không ảnh hưởng phần code đã có.
app.get("/data", async (req, res, next) => {
    try {
        const [results] = await pool.query("SELECT * FROM users");
        res.json({ products: results });
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
