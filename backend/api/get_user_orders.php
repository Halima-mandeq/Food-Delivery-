<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method Not Allowed']);
    exit();
}

require_once '../config/db.php';
require_once '../config/order_support.php';

$userId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;
$orderId = isset($_GET['order_id']) ? (int) $_GET['order_id'] : null;

if ($userId <= 0) {
    http_response_code(400);
    echo json_encode(['error' => 'A valid user_id is required.']);
    exit();
}

try {
    $orders = fetch_orders_for_user($pdo, $userId, $orderId);
    echo json_encode($orders);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Failed to fetch user orders: ' . $e->getMessage(),
    ]);
}
?>
