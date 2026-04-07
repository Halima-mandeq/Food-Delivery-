<?php
require_once '../config/db.php';
try {
    // 1. Create orders table if missing
    $pdo->exec("CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        total_amount DECIMAL(10, 2) NOT NULL,
        status ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
        delivery_address TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");

    // 2. Create order_items table if missing so admin restaurant stats can load.
    $pdo->exec("CREATE TABLE IF NOT EXISTS order_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT NOT NULL,
        product_id INT NOT NULL,
        quantity INT NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
    )");
    
    // 3. Add sample data to see the update
    $pdo->exec("INSERT INTO orders (user_id, total_amount, status) VALUES (1, 25.50, 'Pending'), (2, 60.00, 'Completed') ON DUPLICATE KEY UPDATE id=id");
    
    echo "Orders and order_items tables are ready, and sample order data was updated!";
} catch (Exception $e) { echo "Error: ".$e->getMessage(); }
?>
