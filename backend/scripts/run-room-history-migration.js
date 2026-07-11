const fs = require("node:fs/promises");
const path = require("node:path");
const { pool } = require("../src/config/db");

const run = async () => {
    const source = await fs.readFile(
        path.join(
            __dirname,
            "..",
            "src",
            "config",
            "room_number_history_migration.sql"
        ),
        "utf8"
    );
    const statements = source
        .split(";")
        .map((statement) => statement.trim())
        .filter(Boolean);

    try {
        for (const statement of statements) await pool.query(statement);
        console.log("Migration lịch sử mã phòng thành công.");
    } finally {
        await pool.end();
    }
};

run().catch((error) => {
    console.error("Migration lịch sử mã phòng thất bại:", error.message);
    process.exitCode = 1;
});
