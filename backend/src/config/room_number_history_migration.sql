USE quan_ly_tro;

CREATE TABLE room_number_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  room_id INT NOT NULL,
  room_number VARCHAR(50) NOT NULL,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_room_number_history_room
    FOREIGN KEY (room_id) REFERENCES rooms(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  UNIQUE KEY uq_room_number_history (room_id, room_number)
) ENGINE=InnoDB;

CREATE INDEX idx_room_number_history_room_id ON room_number_history(room_id);
