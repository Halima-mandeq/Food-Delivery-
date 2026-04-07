-- Database: food_delivery_db
CREATE DATABASE IF NOT EXISTS food_delivery_db;
USE food_delivery_db;

-- Table: users
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(15),
    password VARCHAR(255) NOT NULL,
    role ENUM('user', 'admin', 'delivery') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Default Admin Credentials (Email: admin@gmail.com, Password: admin123)
-- Hash generated via password_hash('admin123', PASSWORD_BCRYPT)
INSERT INTO users (full_name, email, password, role)
VALUES (
    'Super Admin',
    'admin@gmail.com',
    '$2y$10$JjgzMzmg3Ctw0g2esWWdS.9T28VD7Ue1AL.gFBxxHD.pk6XEFxnOB6',
    'admin'
)
ON DUPLICATE KEY UPDATE
    role = 'admin',
    password = '$2y$10$JjgzMzmg3Ctw0g2esWWdS.9T28VD7Ue1AL.gFBxxHD.pk6XEFxnOB6';

-- Default Delivery Credentials (Email: delivery@wagba.com, Password: delivery123)
INSERT INTO users (full_name, email, password, role)
VALUES (
    'Saffron Delivery',
    'delivery@wagba.com',
    '$2y$12$HgwJiSmQ5wfH.rSaaF3NWO2dR.Xi0lKyiFMjpfNFpvF5WXb8K/diy',
    'delivery'
)
ON DUPLICATE KEY UPDATE role = 'delivery';

-- Categories Table
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    display_order INT NOT NULL DEFAULT 100,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO categories (name, display_order) VALUES
('Pizza', 1),
('Burger', 2),
('Sushi', 3),
('Desserts', 4),
('Noodles', 5)
ON DUPLICATE KEY UPDATE display_order = VALUES(display_order);

-- Products Table
DROP TABLE IF EXISTS products;
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    category VARCHAR(100),
    image_url VARCHAR(255),
    rating DECIMAL(3, 1) DEFAULT 4.5,
    delivery_fee DECIMAL(10, 2) DEFAULT 0.00,
    delivery_time VARCHAR(50) DEFAULT '20-30 min',
    featured_order INT DEFAULT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Sample Featured Restaurants
INSERT INTO products (
    name,
    description,
    price,
    category,
    image_url,
    rating,
    delivery_fee,
    delivery_time,
    featured_order
) VALUES
('Mamma Mia Pizzeria', 'Italian • Pizza • Pasta', 18.00, 'Pizza', 'images/unnamed.png', 4.8, 0.00, '20-30 min', 1),
('The Burger Joint', 'American • Burgers • Fast Food', 16.50, 'Burger', 'images/unnamed (1).png', 4.5, 2.99, '15-25 min', 2),
('Kyoto Sushi Bar', 'Japanese • Sushi • Ramen', 24.00, 'Sushi', 'images/unnamed (4).png', 4.9, 0.00, '30-40 min', 3);

-- Menu Items Table (Items inside each Restaurant)
CREATE TABLE IF NOT EXISTS menu_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(255),
    category VARCHAR(100),
    is_popular BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (restaurant_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Sample Menu Items for "The Burger Joint" (ID: 2)
INSERT INTO menu_items (
    restaurant_id,
    name,
    description,
    price,
    image_url,
    category,
    is_popular
) VALUES
(2, 'Signature Burger', 'Beef burger with cheddar, lettuce, and tomato', 12.99, 'images/unnamed (1).png', 'Burger', TRUE),
(2, 'Loaded Fries', 'Fries with cheese sauce and burger seasoning', 5.50, 'images/unnamed (1).png', 'Sides', FALSE);

-- Sample Menu Items for "Mamma Mia Pizzeria" (ID: 1)
INSERT INTO menu_items (
    restaurant_id,
    name,
    description,
    price,
    image_url,
    category,
    is_popular
) VALUES
(1, 'Pepperoni Pizza', 'Stone baked pizza with pepperoni and olives', 15.50, 'images/unnamed.png', 'Pizza', TRUE),
(1, 'Garlic Bread', 'Buttery bread with garlic and herbs', 4.50, 'images/unnamed.png', 'Sides', FALSE);

-- Sample Menu Items for "Kyoto Sushi Bar" (ID: 3)
INSERT INTO menu_items (
    restaurant_id,
    name,
    description,
    price,
    image_url,
    category,
    is_popular
) VALUES
(3, 'Dragon Roll', 'Eel roll with avocado and sesame glaze', 17.50, 'images/unnamed (4).png', 'Sushi', TRUE),
(3, 'Spicy Ramen', 'Ramen noodles with rich spicy broth', 13.99, 'images/unnamed (4).png', 'Noodles', TRUE);

-- Home Promotions Table
CREATE TABLE IF NOT EXISTS home_promotions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kind ENUM('banner', 'offer') NOT NULL,
    title VARCHAR(120) NOT NULL,
    subtitle VARCHAR(255) NOT NULL,
    cta_label VARCHAR(80) NOT NULL DEFAULT '',
    icon_key VARCHAR(80) NOT NULL DEFAULT '',
    display_order INT NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_home_promotions_kind_title (kind, title)
);

INSERT INTO home_promotions (
    kind,
    title,
    subtitle,
    cta_label,
    icon_key,
    display_order
) VALUES
('banner', '30% OFF', 'On your first 3 orders', 'ORDER NOW', 'shopping_bag', 1),
('offer', 'Buy 1 Get 1', 'Selected items', '', 'sell', 2),
('offer', 'Free Deliv.', 'Orders > $40', '', 'delivery', 3)
ON DUPLICATE KEY UPDATE
    subtitle = VALUES(subtitle),
    cta_label = VALUES(cta_label),
    icon_key = VALUES(icon_key),
    display_order = VALUES(display_order),
    is_active = TRUE;

-- Orders Table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    restaurant_id INT NULL,
    restaurant_name VARCHAR(255) NULL,
    restaurant_image_url VARCHAR(255) NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    subtotal_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    delivery_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR(50) NOT NULL DEFAULT 'Mastercard',
    status ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
    delivery_address TEXT,
    estimated_delivery_time VARCHAR(50) NOT NULL DEFAULT '25-35 min',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Order Items Table
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NULL,
    menu_item_id INT NULL,
    item_name VARCHAR(255) NULL,
    item_image_url VARCHAR(255) NULL,
    item_notes TEXT NULL,
    item_options TEXT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Sample Data for Dashboard Stats
INSERT INTO orders (user_id, total_amount, status) VALUES
(1, 25.50, 'Pending'),
(2, 15.00, 'Completed');
