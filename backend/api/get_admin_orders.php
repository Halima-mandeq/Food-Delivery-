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
        "SELECT o.id,
                o.user_id,
                o.total_amount,
                o.status,
                o.delivery_address,
                o.created_at,
                COALESCE(u.full_name, CONCAT('Customer #', o.user_id)) AS customer_name,
                COALESCE(u.email, '') AS customer_email,
                u.phone_number AS customer_phone
         FROM orders o
         LEFT JOIN users u ON u.id = o.user_id
         ORDER BY o.created_at DESC, o.id DESC"
    );

    echo json_encode($stmt->fetchAll());
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Failed to fetch admin orders: ' . $e->getMessage(),
    ]);
}
?>
