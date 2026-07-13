USE quan_ly_tro;

ALTER TABLE rooms
  MODIFY COLUMN floor INT NOT NULL,
  MODIFY COLUMN area DECIMAL(10,2) NOT NULL,
  MODIFY COLUMN price DECIMAL(12,2) NOT NULL,
  MODIFY COLUMN deposit DECIMAL(12,2) NOT NULL,
  MODIFY COLUMN status ENUM('available', 'occupied', 'maintenance', 'inactive', 'deleted') NOT NULL DEFAULT 'available',
  ADD COLUMN version INT NOT NULL DEFAULT 1 AFTER status,
  ADD CONSTRAINT chk_rooms_floor CHECK (floor >= 0),
  ADD CONSTRAINT chk_rooms_area CHECK (area > 0),
  ADD CONSTRAINT chk_rooms_price CHECK (price > 0),
  ADD CONSTRAINT chk_rooms_deposit CHECK (deposit > 0);

ALTER TABLE tenants
  DROP FOREIGN KEY fk_tenants_room;
ALTER TABLE tenants
  ADD CONSTRAINT fk_tenants_room
    FOREIGN KEY (room_id) REFERENCES rooms(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

ALTER TABLE utility_readings
  DROP FOREIGN KEY fk_utility_room;
ALTER TABLE utility_readings
  ADD CONSTRAINT fk_utility_room
    FOREIGN KEY (room_id) REFERENCES rooms(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

ALTER TABLE maintenance_requests
  DROP FOREIGN KEY fk_maintenance_room,
  DROP FOREIGN KEY fk_maintenance_tenant;
ALTER TABLE maintenance_requests
  ADD CONSTRAINT fk_maintenance_room
    FOREIGN KEY (room_id) REFERENCES rooms(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  ADD CONSTRAINT fk_maintenance_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT;
