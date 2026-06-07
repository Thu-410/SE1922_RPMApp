CREATE DATABASE OrderFood;
USE OrderFood;

CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    address TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE staffs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,

    role ENUM(
        'admin',
        'manager',
        'kitchen'
    ) DEFAULT 'manager',

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);


CREATE TABLE foods (
    id INT PRIMARY KEY AUTO_INCREMENT,
    category_id INT NOT NULL,

    name VARCHAR(150) NOT NULL,
    description TEXT,

    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),

    thumbnail_url TEXT,

    status ENUM('active', 'inactive') DEFAULT 'active',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_food_category
        FOREIGN KEY (category_id)
        REFERENCES categories(id)
);


CREATE TABLE food_images (
    id INT PRIMARY KEY AUTO_INCREMENT,
    food_id INT NOT NULL,
    image_url TEXT NOT NULL,

    CONSTRAINT fk_food_image
        FOREIGN KEY (food_id)
        REFERENCES foods(id)
        ON DELETE CASCADE
);

CREATE TABLE carts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,

    status ENUM('active', 'ordered', 'cancelled') DEFAULT 'active',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_cart_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
);



CREATE TABLE cart_items (
    id INT PRIMARY KEY AUTO_INCREMENT,

    cart_id INT NOT NULL,
    food_id INT NOT NULL,

    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_cart_item_cart
        FOREIGN KEY (cart_id)
        REFERENCES carts(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_cart_item_food
        FOREIGN KEY (food_id)
        REFERENCES foods(id),

    CONSTRAINT uq_cart_food
        UNIQUE (cart_id, food_id)
);

CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,

    user_id INT NOT NULL,
    cart_id INT,

    receiver_name VARCHAR(100),
    receiver_phone VARCHAR(20),
    delivery_address TEXT,

    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),

    order_status ENUM(
        'pending_payment',
        'paid',
        'preparing',
        'completed',
        'cancelled'
    ) DEFAULT 'pending_payment',

    payment_status ENUM(
        'unpaid',
        'paid',
        'failed'
    ) DEFAULT 'unpaid',

    note TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_order_user
        FOREIGN KEY (user_id)
        REFERENCES users(id),

    CONSTRAINT fk_order_cart
        FOREIGN KEY (cart_id)
        REFERENCES carts(id)
);

CREATE TABLE order_items (
    id INT PRIMARY KEY AUTO_INCREMENT,

    order_id INT NOT NULL,
    food_id INT NULL,

    food_name VARCHAR(150) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    quantity INT NOT NULL CHECK (quantity > 0),
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),

    CONSTRAINT fk_order_item_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_order_item_food
        FOREIGN KEY (food_id)
        REFERENCES foods(id)
        ON DELETE SET NULL
);


CREATE TABLE payments (
    id INT PRIMARY KEY AUTO_INCREMENT,

    order_id INT NOT NULL,

    payment_method ENUM(
        'cash',
        'momo',
        'zalopay',
        'banking'
    ) NOT NULL,

    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),

    payment_status ENUM(
        'pending',
        'success',
        'failed'
    ) DEFAULT 'pending',

    transaction_code VARCHAR(255),

    paid_at TIMESTAMP NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_payment_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE
);

CREATE TABLE food_status_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,

    food_id INT NOT NULL,

    old_status ENUM('active', 'inactive'),
    new_status ENUM('active', 'inactive'),

    changed_by INT,

    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_log_food
        FOREIGN KEY (food_id)
        REFERENCES foods(id),

    CONSTRAINT fk_log_staff
        FOREIGN KEY (changed_by)
        REFERENCES staffs(id)
);
CREATE INDEX idx_foods_category ON foods(category_id);
CREATE INDEX idx_foods_status ON foods(status);

CREATE INDEX idx_cart_user ON carts(user_id);
CREATE INDEX idx_cart_status ON carts(status);

CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);
CREATE INDEX idx_cart_items_food ON cart_items(food_id);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_cart ON orders(cart_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_food ON order_items(food_id);

CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_status ON payments(payment_status);

CREATE INDEX idx_food_logs_food ON food_status_logs(food_id);
CREATE INDEX idx_food_logs_staff ON food_status_logs(changed_by);
