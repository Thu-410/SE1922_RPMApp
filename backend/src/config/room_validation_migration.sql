USE quan_ly_tro;

ALTER TABLE rooms
  MODIFY COLUMN floor INT NOT NULL,
  MODIFY COLUMN area DECIMAL(10,2) NOT NULL,
  MODIFY COLUMN price DECIMAL(12,2) NOT NULL,
  MODIFY COLUMN deposit DECIMAL(12,2) NOT NULL,
  ADD CONSTRAINT chk_rooms_floor CHECK (floor >= 0),
  ADD CONSTRAINT chk_rooms_area CHECK (area > 0),
  ADD CONSTRAINT chk_rooms_price CHECK (price > 0),
  ADD CONSTRAINT chk_rooms_deposit CHECK (deposit > 0);
