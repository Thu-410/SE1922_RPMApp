const assert = require("node:assert/strict");
const fs = require("node:fs/promises");
const http = require("node:http");
const path = require("node:path");
const test = require("node:test");

const app = require("../server");
const {
    ROOM_UPLOAD_DIRECTORY,
    detectImageExtension
} = require("../src/modules/rooms/room-upload");

const PNG_1X1 = Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6Z2QAAAAASUVORK5CYII=",
    "base64"
);

const listen = (server) =>
    new Promise((resolve, reject) => {
        server.once("error", reject);
        server.listen(0, "127.0.0.1", resolve);
    });

const close = (server) =>
    new Promise((resolve, reject) => {
        server.close((error) => (error ? reject(error) : resolve()));
    });

test("nhận diện nội dung các định dạng ảnh được hỗ trợ", () => {
    assert.equal(detectImageExtension(PNG_1X1), "png");
    assert.equal(detectImageExtension(Buffer.from([0xff, 0xd8, 0xff, 0x00])), "jpg");
    assert.equal(detectImageExtension(Buffer.from("GIF89a", "ascii")), "gif");
    assert.equal(detectImageExtension(Buffer.from("not-an-image")), null);
});

test("upload ảnh multipart và phục vụ lại ảnh qua URL HTTP", async () => {
    const server = http.createServer(app);
    await listen(server);

    let savedFile;
    try {
        const address = server.address();
        const baseUrl = `http://127.0.0.1:${address.port}`;
        const form = new FormData();
        form.append("image", new Blob([PNG_1X1], { type: "image/png" }), "room.png");

        const response = await fetch(`${baseUrl}/api/rooms/images`, {
            method: "POST",
            body: form
        });
        const body = await response.json();

        assert.equal(response.status, 201);
        assert.match(body.data.image_url, /^\/uploads\/rooms\/.+\.png$/);

        savedFile = path.join(
            ROOM_UPLOAD_DIRECTORY,
            path.basename(body.data.image_url)
        );
        const storedBytes = await fs.readFile(savedFile);
        assert.deepEqual(storedBytes, PNG_1X1);

        const imageResponse = await fetch(`${baseUrl}${body.data.image_url}`);
        assert.equal(imageResponse.status, 200);
        assert.deepEqual(Buffer.from(await imageResponse.arrayBuffer()), PNG_1X1);
    } finally {
        if (savedFile) await fs.rm(savedFile, { force: true });
        await close(server);
    }
});

test("từ chối tệp không phải ảnh", async () => {
    const server = http.createServer(app);
    await listen(server);

    try {
        const address = server.address();
        const form = new FormData();
        form.append("image", new Blob(["hello"], { type: "text/plain" }), "note.txt");

        const response = await fetch(
            `http://127.0.0.1:${address.port}/api/rooms/images`,
            { method: "POST", body: form }
        );
        const body = await response.json();

        assert.equal(response.status, 400);
        assert.match(body.message, /Chỉ nhận ảnh/);
    } finally {
        await close(server);
    }
});
