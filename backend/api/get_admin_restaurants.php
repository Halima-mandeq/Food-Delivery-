<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once '../config/db.php';
require_once '../config/order_support.php';

try {
    ensure_order_support($pdo);

    $stmt = $pdo->query(
        "SELECT p.*,
                COALESCE(stats.total_orders, 0) AS total_orders
         FROM products p
         LEFT JOIN (
             SELECT restaurant_id, COUNT(*) AS total_orders
             FROM orders
             WHERE restaurant_id IS NOT NULL
             GROUP BY restaurant_id
         ) stats ON stats.restaurant_id = p.id
         ORDER BY p.created_at DESC, p.name ASC"
    );

    echo json_encode($stmt->fetchAll());
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Failed to fetch admin restaurants: ' . $e->getMessage(),
    ]);
}
?>
