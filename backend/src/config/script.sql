DROP DATABASE IF EXISTS quan_ly_tro;
CREATE DATABASE quan_ly_tro
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE quan_ly_tro;

SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. ROLES
-- =========================================================
CREATE TABLE roles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =========================================================
-- 2. USERS
-- role_id: 1 manager, 2 staff, 3 tenant
-- status: active / inactive / locked
-- =========================================================
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  role_id INT NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  avatar_url VARCHAR(500),
  status ENUM('active', 'inactive', 'locked') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role
    FOREIGN KEY (role_id) REFERENCES roles(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_status ON users(status);

-- =========================================================
-- 3. ROOMS
-- status: available / occupied / maintenance / inactive
-- =========================================================
CREATE TABLE rooms (
  id INT AUTO_INCREMENT PRIMARY KEY,
  room_number VARCHAR(50) NOT NULL UNIQUE,
  room_name VARCHAR(150) NOT NULL,
  floor INT NOT NULL,
  area DECIMAL(10,2) NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  deposit DECIMAL(12,2) NOT NULL,
  status ENUM('available', 'occupied', 'maintenance', 'inactive') NOT NULL DEFAULT 'available',
  description TEXT,
  image_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_rooms_floor CHECK (floor >= 0),
  CONSTRAINT chk_rooms_area CHECK (area > 0),
  CONSTRAINT chk_rooms_price CHECK (price > 0),
  CONSTRAINT chk_rooms_deposit CHECK (deposit > 0)
) ENGINE=InnoDB;

CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_rooms_floor ON rooms(floor);

-- Nhiều ảnh chi tiết cho mỗi phòng
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

-- Lịch sử mã phòng để xử lý request cũ/đến chậm và đồng bộ dữ liệu liên quan
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

-- =========================================================
-- 4. TENANTS
-- status: active = đang thuê, left = đã rời đi
-- user_id có thể NULL nếu người thuê chưa có tài khoản đăng nhập
-- =========================================================
CREATE TABLE tenants (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NULL,
  room_id INT NULL,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(150),
  citizen_id VARCHAR(30) UNIQUE,
  date_of_birth DATE,
  hometown VARCHAR(255),
  address VARCHAR(255),
  citizen_front_image_url VARCHAR(500),
  citizen_back_image_url VARCHAR(500),
  is_representative BOOLEAN NOT NULL DEFAULT FALSE,
  status ENUM('active', 'left') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_tenants_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_tenants_room
    FOREIGN KEY (room_id) REFERENCES rooms(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_tenants_user_id ON tenants(user_id);
CREATE INDEX idx_tenants_room_id ON tenants(room_id);
CREATE INDEX idx_tenants_status ON tenants(status);

-- =========================================================
-- 5. CONTRACTS
-- status: pending / active / expired / terminated
-- =========================================================
CREATE TABLE contracts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  room_id INT NOT NULL,
  tenant_id INT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  monthly_price DECIMAL(12,2) NOT NULL,
  deposit_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  status ENUM('pending', 'active', 'expired', 'terminated') NOT NULL DEFAULT 'pending',
  note TEXT,
  terminated_at DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_contracts_room
    FOREIGN KEY (room_id) REFERENCES rooms(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_contracts_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX idx_contracts_room_id ON contracts(room_id);
CREATE INDEX idx_contracts_tenant_id ON contracts(tenant_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_dates ON contracts(start_date, end_date);

-- =========================================================
-- 6. SERVICE PRICES
-- Bảng cấu hình giá điện, nước, dịch vụ
-- =========================================================
CREATE TABLE service_prices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  electric_price DECIMAL(12,2) NOT NULL DEFAULT 0,
  water_price DECIMAL(12,2) NOT NULL DEFAULT 0,
  service_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
  parking_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
  internet_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
  effective_date DATE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE INDEX idx_service_prices_active ON service_prices(is_active);
CREATE INDEX idx_service_prices_effective_date ON service_prices(effective_date);

-- =========================================================
-- 7. UTILITY READINGS
-- Ghi chỉ số điện nước theo phòng/tháng/năm
-- electric_usage và water_usage là cột tự tính
-- =========================================================
CREATE TABLE utility_readings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  room_id INT NOT NULL,
  month TINYINT NOT NULL,
  year SMALLINT NOT NULL,
  old_electric INT NOT NULL DEFAULT 0,
  new_electric INT NOT NULL DEFAULT 0,
  old_water INT NOT NULL DEFAULT 0,
  new_water INT NOT NULL DEFAULT 0,
  electric_usage INT GENERATED ALWAYS AS (new_electric - old_electric) STORED,
  water_usage INT GENERATED ALWAYS AS (new_water - old_water) STORED,
  note TEXT,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_utility_room
    FOREIGN KEY (room_id) REFERENCES rooms(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_utility_created_by
    FOREIGN KEY (created_by) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT chk_utility_month CHECK (month BETWEEN 1 AND 12),
  CONSTRAINT chk_utility_year CHECK (year >= 2020),
  CONSTRAINT chk_utility_electric CHECK (new_electric >= old_electric),
  CONSTRAINT chk_utility_water CHECK (new_water >= old_water),
  UNIQUE KEY uq_utility_room_month_year (room_id, month, year)
) ENGINE=InnoDB;

CREATE INDEX idx_utility_month_year ON utility_readings(month, year);

-- =========================================================
-- 8. PAYMENT ACCOUNTS
-- Thông tin STK/QR của chủ trọ để tenant thanh toán
-- =========================================================
CREATE TABLE payment_accounts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner_name VARCHAR(150) NOT NULL,
  bank_name VARCHAR(150) NOT NULL,
  bank_account_number VARCHAR(50) NOT NULL,
  qr_image_url VARCHAR(500),
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =========================================================
-- 9. INVOICES
-- status: unpaid / paid / overdue / cancelled
-- =========================================================
CREATE TABLE invoices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  room_id INT NOT NULL,
  tenant_id INT NOT NULL,
  contract_id INT NULL,
  payment_account_id INT NULL,
  month TINYINT NOT NULL,
  year SMALLINT NOT NULL,
  room_price DECIMAL(12,2) NOT NULL DEFAULT 0,
  electric_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
  water_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
  service_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
  parking_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
  internet_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
  other_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
  discount DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  status ENUM('unpaid', 'paid', 'overdue', 'cancelled') NOT NULL DEFAULT 'unpaid',
  due_date DATE NOT NULL,
  paid_date DATETIME NULL,
  note TEXT,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_invoices_room
    FOREIGN KEY (room_id) REFERENCES rooms(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_invoices_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_invoices_contract
    FOREIGN KEY (contract_id) REFERENCES contracts(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_invoices_payment_account
    FOREIGN KEY (payment_account_id) REFERENCES payment_accounts(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_invoices_created_by
    FOREIGN KEY (created_by) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT chk_invoices_month CHECK (month BETWEEN 1 AND 12),
  CONSTRAINT chk_invoices_year CHECK (year >= 2020),
  UNIQUE KEY uq_invoice_room_month_year (room_id, month, year)
) ENGINE=InnoDB;

CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_month_year ON invoices(month, year);
CREATE INDEX idx_invoices_tenant_id ON invoices(tenant_id);
CREATE INDEX idx_invoices_room_id ON invoices(room_id);

-- =========================================================
-- 10. INVOICE DETAILS
-- Chi tiết từng khoản tiền trong hóa đơn
-- =========================================================
CREATE TABLE invoice_details (
  id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  item_type ENUM('room', 'electric', 'water', 'service', 'parking', 'internet', 'other') NOT NULL,
  item_name VARCHAR(150) NOT NULL,
  quantity DECIMAL(12,2) NOT NULL DEFAULT 1,
  unit_price DECIMAL(12,2) NOT NULL DEFAULT 0,
  amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_invoice_details_invoice
    FOREIGN KEY (invoice_id) REFERENCES invoices(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_invoice_details_invoice_id ON invoice_details(invoice_id);
CREATE INDEX idx_invoice_details_item_type ON invoice_details(item_type);

-- =========================================================
-- 11. PAYMENTS
-- payment_method: cash / bank_transfer / qr_code / momo / other
-- =========================================================
CREATE TABLE payments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_method ENUM('cash', 'bank_transfer', 'qr_code', 'momo', 'other') NOT NULL DEFAULT 'cash',
  transaction_code VARCHAR(100),
  payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note TEXT,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_payments_invoice
    FOREIGN KEY (invoice_id) REFERENCES invoices(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_payments_created_by
    FOREIGN KEY (created_by) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_payments_invoice_id ON payments(invoice_id);
CREATE INDEX idx_payments_payment_date ON payments(payment_date);

-- =========================================================
-- 12. MAINTENANCE REQUESTS
-- issue_type: electric / water / internet / furniture / lock / cleaning / other
-- status: pending / processing / completed / cancelled
-- =========================================================
CREATE TABLE maintenance_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  room_id INT NOT NULL,
  tenant_id INT NOT NULL,
  title VARCHAR(200) NOT NULL,
  issue_type ENUM('electric', 'water', 'internet', 'furniture', 'lock', 'cleaning', 'other') NOT NULL DEFAULT 'other',
  description TEXT NOT NULL,
  image_url VARCHAR(500),
  status ENUM('pending', 'processing', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
  manager_note TEXT,
  assigned_staff_id INT NULL,
  completed_at DATETIME NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_maintenance_room
    FOREIGN KEY (room_id) REFERENCES rooms(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_maintenance_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_maintenance_staff
    FOREIGN KEY (assigned_staff_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_maintenance_room_id ON maintenance_requests(room_id);
CREATE INDEX idx_maintenance_tenant_id ON maintenance_requests(tenant_id);
CREATE INDEX idx_maintenance_status ON maintenance_requests(status);
CREATE INDEX idx_maintenance_issue_type ON maintenance_requests(issue_type);

-- =========================================================
-- 13. NOTIFICATIONS
-- Thông báo hóa đơn, sửa chữa, hợp đồng...
-- =========================================================
CREATE TABLE notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  type ENUM('invoice', 'payment', 'maintenance', 'contract', 'system') NOT NULL DEFAULT 'system',
  related_type VARCHAR(50),
  related_id INT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notifications_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_type ON notifications(type);

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- INSERT DỮ LIỆU MẪU
-- =========================================================

-- 1. Roles
INSERT INTO roles (id, name, description) VALUES
(1, 'manager', 'Chủ trọ hoặc quản lý toàn bộ hệ thống'),
(2, 'staff', 'Nhân viên hỗ trợ ghi điện nước và xử lý sự cố'),
(3, 'tenant', 'Người thuê phòng');

-- 2. Users
-- Password mẫu đang để dạng text: 123456
-- Nếu backend của bạn dùng bcrypt.compare, hãy hash lại password bằng bcrypt.hash('123456', 10).
INSERT INTO users (id, role_id, full_name, email, password, phone, status) VALUES
(1, 1, 'Nguyễn Văn Quản Lý', 'manager@gmail.com', '123456', '0901000001', 'active'),
(2, 2, 'Trần Văn Nhân Viên', 'staff@gmail.com', '123456', '0901000002', 'active'),
(3, 3, 'Lê Thị Mai', 'mai@gmail.com', '123456', '0901000003', 'active'),
(4, 3, 'Phạm Văn Nam', 'nam@gmail.com', '123456', '0901000004', 'active'),
(5, 3, 'Hoàng Thu Hà', 'ha@gmail.com', '123456', '0901000005', 'active'),
(6, 3, 'Đỗ Minh Đức', 'duc@gmail.com', '123456', '0901000006', 'inactive');

-- 3. Rooms
INSERT INTO rooms (id, room_number, room_name, floor, area, price, deposit, status, description, image_url) VALUES
(1, 'P101', 'Phòng tiêu chuẩn P101', 1, 25.00, 2500000, 2500000, 'occupied', 'Phòng tầng 1 thoáng mát, có cửa sổ lớn, gần cổng và khu để xe. Phòng phù hợp cho 1-2 người ở.', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200'),
(2, 'P102', 'Phòng gác lửng P102', 1, 28.00, 2800000, 2800000, 'occupied', 'Phòng có gác lửng rộng, khu bếp riêng và đầy đủ ánh sáng tự nhiên.', 'https://images.unsplash.com/photo-1560185007-c5ca9d2c014d?w=1200'),
(3, 'P201', 'Phòng ban công P201', 2, 30.00, 3000000, 3000000, 'available', 'Phòng trống sạch sẽ, có ban công riêng, phù hợp cho gia đình nhỏ hoặc hai người đi làm.', 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200'),
(4, 'P202', 'Phòng tiện nghi P202', 2, 22.00, 2200000, 2200000, 'maintenance', 'Phòng đang sửa lại nhà vệ sinh và thay mới hệ thống đèn, dự kiến sớm hoàn thành.', 'https://images.unsplash.com/photo-1560448075-bb485b067938?w=1200'),
(5, 'P301', 'Phòng cao cấp P301', 3, 35.00, 3500000, 3500000, 'inactive', 'Phòng diện tích lớn ở tầng 3, hiện tạm ngừng sử dụng để nâng cấp nội thất.', 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1200');

INSERT INTO room_images (room_id, image_url, sort_order) VALUES
(1, 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200', 0),
(1, 'https://images.unsplash.com/photo-1560185008-b033106af5c3?w=1200', 1),
(1, 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=1200', 2),
(2, 'https://images.unsplash.com/photo-1560185007-c5ca9d2c014d?w=1200', 0),
(2, 'https://images.unsplash.com/photo-1560448205-4d9b3e6bb6db?w=1200', 1),
(2, 'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=1200', 2),
(3, 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200', 0),
(3, 'https://images.unsplash.com/photo-1564078516393-cf04bd966897?w=1200', 1),
(3, 'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=1200', 2),
(4, 'https://images.unsplash.com/photo-1560448075-bb485b067938?w=1200', 0),
(4, 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=1200', 1),
(5, 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1200', 0),
(5, 'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?w=1200', 1),
(5, 'https://images.unsplash.com/photo-1615874694520-474822394e73?w=1200', 2);

-- 4. Tenants
INSERT INTO tenants (id, user_id, room_id, full_name, phone, email, citizen_id, date_of_birth, hometown, address, is_representative, status) VALUES
(1, 3, 1, 'Lê Thị Mai', '0901000003', 'mai@gmail.com', '001200000001', '2001-05-12', 'Hà Nội', 'Thanh Xuân, Hà Nội', TRUE, 'active'),
(2, 4, 2, 'Phạm Văn Nam', '0901000004', 'nam@gmail.com', '001200000002', '2000-08-20', 'Nam Định', 'Mỹ Lộc, Nam Định', TRUE, 'active'),
(3, 5, 1, 'Hoàng Thu Hà', '0901000005', 'ha@gmail.com', '001200000003', '2002-03-15', 'Hải Phòng', 'Lê Chân, Hải Phòng', FALSE, 'active'),
(4, 6, NULL, 'Đỗ Minh Đức', '0901000006', 'duc@gmail.com', '001200000004', '1999-11-09', 'Nghệ An', 'Vinh, Nghệ An', TRUE, 'left');

-- 5. Contracts
INSERT INTO contracts (id, room_id, tenant_id, start_date, end_date, monthly_price, deposit_amount, status, note, terminated_at) VALUES
(1, 1, 1, '2026-01-01', '2026-12-31', 2500000, 2500000, 'active', 'Hợp đồng phòng P101, đại diện thuê là Lê Thị Mai', NULL),
(2, 2, 2, '2026-02-01', '2027-01-31', 2800000, 2800000, 'active', 'Hợp đồng phòng P102', NULL),
(3, 5, 4, '2025-06-01', '2026-05-31', 3500000, 3500000, 'terminated', 'Người thuê đã trả phòng', '2026-05-31');

-- 6. Service prices
INSERT INTO service_prices (id, electric_price, water_price, service_fee, parking_fee, internet_fee, effective_date, is_active) VALUES
(1, 3500, 15000, 150000, 100000, 100000, '2026-01-01', TRUE),
(2, 3800, 16000, 170000, 120000, 120000, '2026-08-01', FALSE);

-- 7. Payment account
INSERT INTO payment_accounts (id, owner_name, bank_name, bank_account_number, qr_image_url, is_default, status) VALUES
(1, 'NGUYEN VAN QUAN LY', 'Vietcombank', '0123456789', 'https://example.com/qr/vietcombank-0123456789.png', TRUE, 'active');

-- 8. Utility readings tháng 06/2026
INSERT INTO utility_readings (id, room_id, month, year, old_electric, new_electric, old_water, new_water, note, created_by) VALUES
(1, 1, 6, 2026, 1000, 1100, 200, 210, 'Chỉ số tháng 06 phòng P101', 2),
(2, 2, 6, 2026, 850, 900, 180, 188, 'Chỉ số tháng 06 phòng P102', 2),
(3, 3, 6, 2026, 0, 0, 0, 0, 'Phòng trống chưa sử dụng điện nước', 2);

-- 9. Invoices
INSERT INTO invoices (
  id, room_id, tenant_id, contract_id, payment_account_id,
  month, year,
  room_price, electric_fee, water_fee, service_fee, parking_fee, internet_fee, other_fee, discount, total_amount,
  status, due_date, paid_date, note, created_by
) VALUES
(1, 1, 1, 1, 1, 6, 2026, 2500000, 350000, 150000, 150000, 100000, 100000, 0, 0, 3350000, 'paid', '2026-07-05', '2026-07-01 10:30:00', 'Hóa đơn tháng 06/2026 phòng P101', 1),
(2, 2, 2, 2, 1, 6, 2026, 2800000, 175000, 120000, 150000, 0, 100000, 0, 0, 3345000, 'unpaid', '2026-07-05', NULL, 'Hóa đơn tháng 06/2026 phòng P102', 1),
(3, 1, 1, 1, 1, 5, 2026, 2500000, 280000, 120000, 150000, 100000, 100000, 0, 0, 3250000, 'paid', '2026-06-05', '2026-06-02 09:00:00', 'Hóa đơn tháng 05/2026 phòng P101', 1),
(4, 2, 2, 2, 1, 5, 2026, 2800000, 210000, 135000, 150000, 0, 100000, 0, 0, 3395000, 'overdue', '2026-06-05', NULL, 'Hóa đơn tháng 05/2026 phòng P102 chưa thanh toán', 1);

-- 10. Invoice details
INSERT INTO invoice_details (invoice_id, item_type, item_name, quantity, unit_price, amount, note) VALUES
-- Invoice 1
(1, 'room', 'Tiền phòng P101 tháng 06/2026', 1, 2500000, 2500000, NULL),
(1, 'electric', 'Tiền điện: 100 số x 3.500', 100, 3500, 350000, NULL),
(1, 'water', 'Tiền nước: 10 khối x 15.000', 10, 15000, 150000, NULL),
(1, 'service', 'Phí dịch vụ', 1, 150000, 150000, NULL),
(1, 'parking', 'Phí gửi xe', 1, 100000, 100000, NULL),
(1, 'internet', 'Phí internet', 1, 100000, 100000, NULL),
-- Invoice 2
(2, 'room', 'Tiền phòng P102 tháng 06/2026', 1, 2800000, 2800000, NULL),
(2, 'electric', 'Tiền điện: 50 số x 3.500', 50, 3500, 175000, NULL),
(2, 'water', 'Tiền nước: 8 khối x 15.000', 8, 15000, 120000, NULL),
(2, 'service', 'Phí dịch vụ', 1, 150000, 150000, NULL),
(2, 'internet', 'Phí internet', 1, 100000, 100000, NULL),
-- Invoice 3
(3, 'room', 'Tiền phòng P101 tháng 05/2026', 1, 2500000, 2500000, NULL),
(3, 'electric', 'Tiền điện tháng 05/2026', 80, 3500, 280000, NULL),
(3, 'water', 'Tiền nước tháng 05/2026', 8, 15000, 120000, NULL),
(3, 'service', 'Phí dịch vụ', 1, 150000, 150000, NULL),
(3, 'parking', 'Phí gửi xe', 1, 100000, 100000, NULL),
(3, 'internet', 'Phí internet', 1, 100000, 100000, NULL),
-- Invoice 4
(4, 'room', 'Tiền phòng P102 tháng 05/2026', 1, 2800000, 2800000, NULL),
(4, 'electric', 'Tiền điện tháng 05/2026', 60, 3500, 210000, NULL),
(4, 'water', 'Tiền nước tháng 05/2026', 9, 15000, 135000, NULL),
(4, 'service', 'Phí dịch vụ', 1, 150000, 150000, NULL),
(4, 'internet', 'Phí internet', 1, 100000, 100000, NULL);

-- 11. Payments
INSERT INTO payments (id, invoice_id, amount, payment_method, transaction_code, payment_date, note, created_by) VALUES
(1, 1, 3350000, 'bank_transfer', 'VCB202607010001', '2026-07-01 10:30:00', 'Chuyển khoản vào STK chủ trọ', 1),
(2, 3, 3250000, 'qr_code', 'QR202606020001', '2026-06-02 09:00:00', 'Thanh toán bằng QR', 1);

-- 12. Maintenance requests
INSERT INTO maintenance_requests (
  id, room_id, tenant_id, title, issue_type, description, image_url, status, manager_note, assigned_staff_id, completed_at
) VALUES
(1, 1, 1, 'Bóng đèn nhà vệ sinh bị cháy', 'electric', 'Bóng đèn trong nhà vệ sinh không sáng, cần thay bóng mới.', NULL, 'completed', 'Đã thay bóng đèn mới ngày 25/06.', 2, '2026-06-25 15:00:00'),
(2, 2, 2, 'Vòi nước bị rò rỉ', 'water', 'Vòi nước lavabo bị rỉ nước liên tục.', NULL, 'processing', 'Nhân viên đã tiếp nhận, đang đặt lịch sửa.', 2, NULL),
(3, 1, 3, 'Wifi yếu vào buổi tối', 'internet', 'Tốc độ mạng yếu trong khoảng 20h-23h.', NULL, 'pending', NULL, NULL, NULL);

-- 13. Notifications
INSERT INTO notifications (id, user_id, title, content, type, related_type, related_id, is_read) VALUES
(1, 3, 'Hóa đơn tháng 06/2026 đã được tạo', 'Bạn có hóa đơn tháng 06/2026 với tổng tiền 3.350.000đ.', 'invoice', 'invoice', 1, TRUE),
(2, 4, 'Hóa đơn tháng 06/2026 đã được tạo', 'Bạn có hóa đơn tháng 06/2026 với tổng tiền 3.345.000đ, hạn thanh toán 05/07/2026.', 'invoice', 'invoice', 2, FALSE),
(3, 2, 'Có yêu cầu sửa chữa mới', 'Phòng P101 báo sự cố wifi yếu vào buổi tối.', 'maintenance', 'maintenance_request', 3, FALSE),
(4, 3, 'Yêu cầu sửa chữa đã hoàn thành', 'Yêu cầu thay bóng đèn nhà vệ sinh đã được xử lý.', 'maintenance', 'maintenance_request', 1, TRUE);

-- =========================================================
-- VIEW HỖ TRỢ DASHBOARD / REPORTS
-- =========================================================

-- Tổng quan dashboard tháng hiện tại theo CURDATE()
CREATE OR REPLACE VIEW v_dashboard_summary AS
SELECT
  (SELECT COUNT(*) FROM rooms) AS total_rooms,
  (SELECT COUNT(*) FROM rooms WHERE status = 'occupied') AS occupied_rooms,
  (SELECT COUNT(*) FROM rooms WHERE status = 'available') AS available_rooms,
  (SELECT COUNT(*) FROM rooms WHERE status = 'maintenance') AS maintenance_rooms,
  (SELECT COUNT(*) FROM invoices WHERE status IN ('unpaid', 'overdue')) AS unpaid_invoices,
  (SELECT IFNULL(SUM(total_amount), 0)
   FROM invoices
   WHERE status = 'paid'
     AND month = MONTH(CURDATE())
     AND year = YEAR(CURDATE())) AS revenue_this_month,
  (SELECT COUNT(*) FROM maintenance_requests WHERE status = 'pending') AS pending_maintenance_requests;

-- Báo cáo doanh thu theo tháng/năm
CREATE OR REPLACE VIEW v_revenue_by_month AS
SELECT
  year,
  month,
  COUNT(*) AS total_invoices,
  SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) AS paid_invoices,
  SUM(CASE WHEN status IN ('unpaid', 'overdue') THEN 1 ELSE 0 END) AS unpaid_invoices,
  IFNULL(SUM(total_amount), 0) AS total_invoice_amount,
  IFNULL(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) AS paid_amount,
  IFNULL(SUM(CASE WHEN status IN ('unpaid', 'overdue') THEN total_amount ELSE 0 END), 0) AS debt_amount
FROM invoices
GROUP BY year, month;

-- Danh sách công nợ
CREATE OR REPLACE VIEW v_debt_report AS
SELECT
  i.id AS invoice_id,
  r.room_number,
  t.full_name AS tenant_name,
  t.phone AS tenant_phone,
  i.month,
  i.year,
  i.total_amount,
  i.status,
  i.due_date,
  DATEDIFF(CURDATE(), i.due_date) AS overdue_days
FROM invoices i
JOIN rooms r ON i.room_id = r.id
JOIN tenants t ON i.tenant_id = t.id
WHERE i.status IN ('unpaid', 'overdue')
ORDER BY i.due_date ASC;

-- Tình trạng phòng
CREATE OR REPLACE VIEW v_room_occupancy AS
SELECT
  status,
  COUNT(*) AS total
FROM rooms
GROUP BY status;
