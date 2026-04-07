<?php

function ensure_order_support(PDO $pdo): void
{
    static $isInitialized = false;

    if ($isInitialized) {
        return;
    }

    $pdo->exec(
        "CREATE TABLE IF NOT EXISTS orders (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            total_amount DECIMAL(10, 2) NOT NULL,
            status ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
            delivery_address TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )"
    );

    $pdo->exec(
        "CREATE TABLE IF NOT EXISTS order_items (
            id INT AUTO_INCREMENT PRIMARY KEY,
            order_id INT NOT NULL,
            product_id INT NULL,
            quantity INT NOT NULL,
            price DECIMAL(10, 2) NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
        )"
    );

    $orderColumns = table_columns($pdo, 'orders');
    if (!isset($orderColumns['restaurant_id'])) {
        $pdo->exec(
            "ALTER TABLE orders
             ADD COLUMN restaurant_id INT NULL AFTER user_id"
        );
    }
    if (!isset($orderColumns['restaurant_name'])) {
        $pdo->exec(
            "ALTER TABLE orders
             ADD COLUMN restaurant_name VARCHAR(255) NULL AFTER restaurant_id"
        );
    }
    if (!isset($orderColumns['restaurant_image_url'])) {
        $pdo->exec(
            "ALTER TABLE orders
             ADD COLUMN restaurant_image_url VARCHAR(255) NULL AFTER restaurant_name"
        );
    }
    if (!isset($orderColumns['subtotal_amount'])) {
        $pdo->exec(
            "ALTER TABLE orders
             ADD COLUMN subtotal_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00
             AFTER total_amount"
        );
    }
    if (!isset($orderColumns['delivery_fee'])) {
        $pdo->exec(
            "ALTER TABLE orders
             ADD COLUMN delivery_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00
             AFTER subtotal_amount"
        );
    }
    if (!isset($orderColumns['tax_amount'])) {
        $pdo->exec(
            "ALTER TABLE orders
             ADD COLUMN tax_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00
             AFTER delivery_fee"
        );
    }
    if (!isset($orderColumns['payment_method'])) {
        $pdo->exec(
            "ALTER TABLE orders
             ADD COLUMN payment_method VARCHAR(50) NOT NULL DEFAULT 'Mastercard'
             AFTER tax_amount"
        );
    }
    if (!isset($orderColumns['estimated_delivery_time'])) {
        $pdo->exec(
            "ALTER TABLE orders
             ADD COLUMN estimated_delivery_time VARCHAR(50) NOT NULL DEFAULT '25-35 min'
             AFTER delivery_address"
        );
    }

    $orderItemColumns = table_columns($pdo, 'order_items');
    if (isset($orderItemColumns['product_id'])) {
        $pdo->exec(
            "ALTER TABLE order_items
             MODIFY COLUMN product_id INT NULL"
        );
    }
    if (!isset($orderItemColumns['menu_item_id'])) {
        $pdo->exec(
            "ALTER TABLE order_items
             ADD COLUMN menu_item_id INT NULL AFTER product_id"
        );
    }
    if (!isset($orderItemColumns['item_name'])) {
        $pdo->exec(
            "ALTER TABLE order_items
             ADD COLUMN item_name VARCHAR(255) NULL AFTER menu_item_id"
        );
    }
    if (!isset($orderItemColumns['item_image_url'])) {
        $pdo->exec(
            "ALTER TABLE order_items
             ADD COLUMN item_image_url VARCHAR(255) NULL AFTER item_name"
        );
    }
    if (!isset($orderItemColumns['item_notes'])) {
        $pdo->exec(
            "ALTER TABLE order_items
             ADD COLUMN item_notes TEXT NULL AFTER item_image_url"
        );
    }
    if (!isset($orderItemColumns['item_options'])) {
        $pdo->exec(
            "ALTER TABLE order_items
             ADD COLUMN item_options TEXT NULL AFTER item_notes"
        );
    }

    $isInitialized = true;
}

function fetch_orders_for_user(PDO $pdo, int $userId, ?int $orderId = null): array
{
    ensure_order_support($pdo);

    $query = "
        SELECT o.id,
               o.user_id,
               o.restaurant_id,
               COALESCE(NULLIF(TRIM(o.restaurant_name), ''), p.name, 'Restaurant') AS restaurant_name,
               COALESCE(NULLIF(TRIM(o.restaurant_image_url), ''), p.image_url, '') AS restaurant_image_url,
               o.total_amount,
               o.subtotal_amount,
               o.delivery_fee,
               o.tax_amount,
               o.payment_method,
               o.status,
               o.delivery_address,
               o.estimated_delivery_time,
               o.created_at,
               COALESCE(SUM(oi.quantity), 0) AS total_items,
               COALESCE(
                   GROUP_CONCAT(
                       COALESCE(NULLIF(TRIM(oi.item_name), ''), 'Menu Item')
                       ORDER BY oi.id ASC
                       SEPARATOR ', '
                   ),
                   ''
               ) AS items_label
        FROM orders o
        LEFT JOIN products p ON p.id = o.restaurant_id
        LEFT JOIN order_items oi ON oi.order_id = o.id
        WHERE o.user_id = :user_id";

    if ($orderId !== null) {
        $query .= " AND o.id = :order_id";
    }

    $query .= "
        GROUP BY o.id,
                 o.user_id,
                 o.restaurant_id,
                 o.restaurant_name,
                 o.restaurant_image_url,
                 p.name,
                 p.image_url,
                 o.total_amount,
                 o.subtotal_amount,
                 o.delivery_fee,
                 o.tax_amount,
                 o.payment_method,
                 o.status,
                 o.delivery_address,
                 o.estimated_delivery_time,
                 o.created_at
        ORDER BY o.created_at DESC, o.id DESC";

    $stmt = $pdo->prepare($query);
    $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);

    if ($orderId !== null) {
        $stmt->bindValue(':order_id', $orderId, PDO::PARAM_INT);
    }

    $stmt->execute();

    return $stmt->fetchAll();
}

function normalize_payment_method(?string $value): string
{
    $normalized = strtolower(trim((string) $value));

    return match ($normalized) {
        'evc' => 'EVC',
        default => 'Mastercard',
    };
}

function normalize_delivery_time(?string $value): string
{
    $trimmed = trim((string) $value);
    return $trimmed !== '' ? $trimmed : '25-35 min';
}

function table_columns(PDO $pdo, string $table): array
{
    $stmt = $pdo->query("SHOW COLUMNS FROM `$table`");
    $columns = [];

    foreach ($stmt->fetchAll() as $column) {
        $columns[$column['Field']] = $column;
    }

    return $columns;
}

?>
