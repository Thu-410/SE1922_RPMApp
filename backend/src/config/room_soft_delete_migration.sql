USE quan_ly_tro;

-- Giữ nguyên bản ghi phòng và toàn bộ khóa ngoại lịch sử.
-- Chỉ bổ sung trạng thái nội bộ `deleted` để thay cho DELETE vật lý.
ALTER TABLE rooms
  MODIFY COLUMN status
  ENUM('available', 'occupied', 'maintenance', 'inactive', 'deleted')
  NOT NULL DEFAULT 'available';
