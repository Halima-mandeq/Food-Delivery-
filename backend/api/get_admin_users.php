<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once '../config/db.php';

try {
    $stmt = $pdo->query(
        "SELECT u.id,
                u.full_name,
                u.email,
                u.phone_number,
                u.role,
                u.created_at,
                COALESCE(COUNT(o.id), 0) AS total_orders
         FROM users u
         LEFT JOIN orders o ON o.user_id = u.id
         GROUP BY u.id
         ORDER BY u.created_at DESC, u.full_name ASC"
    );

    echo json_encode($stmt->fetchAll());
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Failed to fetch admin users: ' . $e->getMessage(),
    ]);
}
?>
