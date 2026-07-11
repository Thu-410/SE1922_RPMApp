-- Chạy file này đúng một lần nếu database quan_ly_tro đã tồn tại.
-- Migration giữ nguyên toàn bộ dữ liệu phòng, hợp đồng và người thuê hiện có.
USE quan_ly_tro;

ALTER TABLE rooms
  ADD COLUMN room_name VARCHAR(150) NULL AFTER room_number;

UPDATE rooms
SET room_name = CONCAT('Phòng ', room_number)
WHERE room_name IS NULL OR TRIM(room_name) = '';

ALTER TABLE rooms
  MODIFY COLUMN room_name VARCHAR(150) NOT NULL;

CREATE TABLE room_images (
  id INT AUTO_INCREMENT PRIMARY KEY,
  room_id INT NOT NULL,
  image_url VARCHAR(500) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_room_images_room
    FOREIGN KEY (room_id) REFERENCES rooms(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_room_images_room_id ON room_images(room_id);

-- Chuyển ảnh đại diện cũ sang bảng ảnh chi tiết nếu có.
INSERT INTO room_images (room_id, image_url, sort_order)
SELECT id, image_url, 0
FROM rooms
WHERE image_url IS NOT NULL AND TRIM(image_url) <> '';
