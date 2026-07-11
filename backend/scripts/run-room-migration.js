const fs = require("node:fs/promises");
const path = require("node:path");
const { pool } = require("../src/config/db");

const run = async () => {
    const migrationPath = path.join(
        __dirname,
        "..",
        "src",
        "config",
        "room_images_migration.sql"
    );
    const source = await fs.readFile(migrationPath, "utf8");
    const statements = source
        .split(";")
        .map((statement) =>
            statement
                .split(/\r?\n/)
                .filter((line) => !line.trim().startsWith("--"))
                .join("\n")
                .trim()
        )
        .filter(Boolean);

    try {
        for (const statement of statements) {
            await pool.query(statement);
        }
        console.log("Migration tên phòng và ảnh chi tiết thành công.");
    } finally {
        await pool.end();
    }
};

run().catch((error) => {
    console.error("Migration thất bại:", error.message);
    process.exitCode = 1;
});
