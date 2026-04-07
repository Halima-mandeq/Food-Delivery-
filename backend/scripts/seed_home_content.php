<?php
require_once __DIR__ . '/../config/db.php';

header('Content-Type: text/plain');

function columnExists(PDO $pdo, string $table, string $column): bool
{
    $stmt = $pdo->prepare(
        "SELECT COUNT(*)
         FROM INFORMATION_SCHEMA.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = ?
           AND COLUMN_NAME = ?"
    );
    $stmt->execute([$table, $column]);

    return (int) $stmt->fetchColumn() > 0;
}

function upsertProduct(PDO $pdo, array $product): int
{
    $select = $pdo->prepare("SELECT id FROM products WHERE name = ? LIMIT 1");
    $select->execute([$product['name']]);
    $existingId = $select->fetchColumn();

    if ($existingId) {
        $update = $pdo->prepare(
            "UPDATE products
             SET description = ?,
                 price = ?,
                 category = ?,
                 image_url = ?,
                 rating = ?,
                 delivery_fee = ?,
                 delivery_time = ?,
                 is_available = 1,
                 featured_order = ?
             WHERE id = ?"
        );

        $update->execute([
            $product['description'],
            $product['price'],
            $product['category'],
            $product['image_url'],
            $product['rating'],
            $product['delivery_fee'],
            $product['delivery_time'],
            $product['featured_order'],
            $existingId,
        ]);

        return (int) $existingId;
    }

    $insert = $pdo->prepare(
        "INSERT INTO products (
            name,
            description,
            price,
            category,
            image_url,
            rating,
            delivery_fee,
            delivery_time,
            is_available,
            featured_order
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?)"
    );

    $insert->execute([
        $product['name'],
        $product['description'],
        $product['price'],
        $product['category'],
        $product['image_url'],
        $product['rating'],
        $product['delivery_fee'],
        $product['delivery_time'],
        $product['featured_order'],
    ]);

    return (int) $pdo->lastInsertId();
}

function imagePathForCategory(string $category): string
{
    $normalized = strtolower(trim($category));

    switch ($normalized) {
        case 'burger':
        case 'burgers':
        case 'burrket':
            return 'images/unnamed (1).png';
        case 'sushi':
            return 'images/unnamed (4).png';
        case 'dessert':
        case 'desserts':
            return 'images/unnamed (3).png';
        case 'salads':
            return 'images/unnamed (2).png';
        case 'noodles':
            return 'images/unnamed (4).png';
        case 'pizza':
        default:
            return 'images/unnamed.png';
    }
}

try {
    $pdo->exec(
        "CREATE TABLE IF NOT EXISTS categories (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL UNIQUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )"
    );

    if (!columnExists($pdo, 'categories', 'display_order')) {
        $pdo->exec(
            "ALTER TABLE categories
             ADD COLUMN display_order INT NOT NULL DEFAULT 100 AFTER name"
        );
    }

    if (!columnExists($pdo, 'products', 'featured_order')) {
        $pdo->exec(
            "ALTER TABLE products
             ADD COLUMN featured_order INT NULL DEFAULT NULL AFTER delivery_time"
        );
    }

    $pdo->exec(
        "CREATE TABLE IF NOT EXISTS home_promotions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            kind ENUM('banner', 'offer') NOT NULL,
            title VARCHAR(120) NOT NULL,
            subtitle VARCHAR(255) NOT NULL,
            cta_label VARCHAR(80) NOT NULL DEFAULT '',
            icon_key VARCHAR(80) NOT NULL DEFAULT '',
            display_order INT NOT NULL DEFAULT 100,
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uq_home_promotions_kind_title (kind, title)
        )"
    );

    $categorySeed = [
        ['name' => 'Pizza', 'display_order' => 1],
        ['name' => 'Burger', 'display_order' => 2],
        ['name' => 'Sushi', 'display_order' => 3],
        ['name' => 'Desserts', 'display_order' => 4],
        ['name' => 'Noodles', 'display_order' => 5],
    ];

    $categoryStmt = $pdo->prepare(
        "INSERT INTO categories (name, display_order)
         VALUES (?, ?)
         ON DUPLICATE KEY UPDATE display_order = VALUES(display_order)"
    );

    foreach ($categorySeed as $category) {
        $categoryStmt->execute([
            $category['name'],
            $category['display_order'],
        ]);
    }

    $productSeed = [
        [
            'name' => 'Mamma Mia Pizzeria',
            'description' => 'Italian • Pizza • Pasta',
            'price' => 18.00,
            'category' => 'Pizza',
            'image_url' => 'images/unnamed.png',
            'rating' => 4.8,
            'delivery_fee' => 0.00,
            'delivery_time' => '20-30 min',
            'featured_order' => 1,
            'menu_items' => [
                [
                    'name' => 'Pepperoni Pizza',
                    'description' => 'Stone baked pizza with pepperoni and olives',
                    'price' => 15.50,
                    'image_url' => 'images/unnamed.png',
                    'category' => 'Pizza',
                    'is_popular' => 1,
                ],
                [
                    'name' => 'Garlic Bread',
                    'description' => 'Buttery bread with garlic and herbs',
                    'price' => 4.50,
                    'image_url' => 'images/unnamed.png',
                    'category' => 'Sides',
                    'is_popular' => 0,
                ],
            ],
        ],
        [
            'name' => 'The Burger Joint',
            'description' => 'American • Burgers • Fast Food',
            'price' => 16.50,
            'category' => 'Burger',
            'image_url' => 'images/unnamed (1).png',
            'rating' => 4.5,
            'delivery_fee' => 2.99,
            'delivery_time' => '15-25 min',
            'featured_order' => 2,
            'menu_items' => [
                [
                    'name' => 'Signature Burger',
                    'description' => 'Beef burger with cheddar, lettuce, and tomato',
                    'price' => 12.99,
                    'image_url' => 'images/unnamed (1).png',
                    'category' => 'Burger',
                    'is_popular' => 1,
                ],
                [
                    'name' => 'Loaded Fries',
                    'description' => 'Fries with cheese sauce and burger seasoning',
                    'price' => 5.50,
                    'image_url' => 'images/unnamed (1).png',
                    'category' => 'Sides',
                    'is_popular' => 0,
                ],
            ],
        ],
        [
            'name' => 'Kyoto Sushi Bar',
            'description' => 'Japanese • Sushi • Ramen',
            'price' => 24.00,
            'category' => 'Sushi',
            'image_url' => 'images/unnamed (4).png',
            'rating' => 4.9,
            'delivery_fee' => 0.00,
            'delivery_time' => '30-40 min',
            'featured_order' => 3,
            'menu_items' => [
                [
                    'name' => 'Dragon Roll',
                    'description' => 'Eel roll with avocado and sesame glaze',
                    'price' => 17.50,
                    'image_url' => 'images/unnamed (4).png',
                    'category' => 'Sushi',
                    'is_popular' => 1,
                ],
                [
                    'name' => 'Spicy Ramen',
                    'description' => 'Ramen noodles with rich spicy broth',
                    'price' => 13.99,
                    'image_url' => 'images/unnamed (4).png',
                    'category' => 'Noodles',
                    'is_popular' => 1,
                ],
            ],
        ],
    ];

    $deleteMenuItems = $pdo->prepare(
        "DELETE FROM menu_items WHERE restaurant_id = ?"
    );
    $insertMenuItem = $pdo->prepare(
        "INSERT INTO menu_items (
            restaurant_id,
            name,
            description,
            price,
            image_url,
            category,
            is_popular
        ) VALUES (?, ?, ?, ?, ?, ?, ?)"
    );

    foreach ($productSeed as $product) {
        $productId = upsertProduct($pdo, $product);

        $deleteMenuItems->execute([$productId]);
        foreach ($product['menu_items'] as $menuItem) {
            $insertMenuItem->execute([
                $productId,
                $menuItem['name'],
                $menuItem['description'],
                $menuItem['price'],
                $menuItem['image_url'],
                $menuItem['category'],
                $menuItem['is_popular'],
            ]);
        }
    }

    $promotionSeed = [
        [
            'kind' => 'banner',
            'title' => '30% OFF',
            'subtitle' => 'On your first 3 orders',
            'cta_label' => 'ORDER NOW',
            'icon_key' => 'shopping_bag',
            'display_order' => 1,
        ],
        [
            'kind' => 'offer',
            'title' => 'Buy 1 Get 1',
            'subtitle' => 'Selected items',
            'cta_label' => '',
            'icon_key' => 'sell',
            'display_order' => 2,
        ],
        [
            'kind' => 'offer',
            'title' => 'Free Deliv.',
            'subtitle' => 'Orders > $40',
            'cta_label' => '',
            'icon_key' => 'delivery',
            'display_order' => 3,
        ],
    ];

    $promotionStmt = $pdo->prepare(
        "INSERT INTO home_promotions (
            kind,
            title,
            subtitle,
            cta_label,
            icon_key,
            display_order,
            is_active
        ) VALUES (?, ?, ?, ?, ?, ?, 1)
         ON DUPLICATE KEY UPDATE
            subtitle = VALUES(subtitle),
            cta_label = VALUES(cta_label),
            icon_key = VALUES(icon_key),
            display_order = VALUES(display_order),
            is_active = 1"
    );

    foreach ($promotionSeed as $promotion) {
        $promotionStmt->execute([
            $promotion['kind'],
            $promotion['title'],
            $promotion['subtitle'],
            $promotion['cta_label'],
            $promotion['icon_key'],
            $promotion['display_order'],
        ]);
    }

    $legacyImages = [
        'images/burger.png',
        'images/pizza.png',
        'images/salad.png',
        'images/login_hero.png',
        'images/onboarding_hero.png',
    ];

    $legacyPlaceholders = implode(',', array_fill(0, count($legacyImages), '?'));
    $legacyProducts = $pdo->prepare(
        "SELECT id, category
         FROM products
         WHERE image_url IS NULL
            OR TRIM(image_url) = ''
            OR image_url IN ($legacyPlaceholders)"
    );
    $legacyProducts->execute($legacyImages);

    $updateImage = $pdo->prepare(
        "UPDATE products SET image_url = ? WHERE id = ?"
    );

    foreach ($legacyProducts->fetchAll(PDO::FETCH_ASSOC) as $legacyProduct) {
        $updateImage->execute([
            imagePathForCategory((string) ($legacyProduct['category'] ?? '')),
            $legacyProduct['id'],
        ]);
    }

    echo "Home content seeded successfully.\n";
} catch (Throwable $e) {
    http_response_code(500);
    echo 'Failed to seed home content: ' . $e->getMessage() . "\n";
}
?>
