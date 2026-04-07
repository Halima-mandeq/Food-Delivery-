<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
require_once '../config/db.php';
require_once '../config/order_support.php';

try {
    ensure_order_support($pdo);

    // Total Revenue
    $stmt = $pdo->query("SELECT SUM(total_amount) as total FROM orders WHERE status = 'Completed'");
    $revenue = $stmt->fetch()['total'] ?? 0;

    // Total Orders
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM orders");
    $totalOrders = $stmt->fetch()['count'] ?? 0;

    // Active Orders
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM orders WHERE status = 'Pending'");
    $activeOrders = $stmt->fetch()['count'] ?? 0;

    // Deliveries
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM orders WHERE status = 'Completed'");
    $deliveries = $stmt->fetch()['count'] ?? 0;

    // New Users
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)");
    $newUsers = $stmt->fetch()['count'] ?? 0;

    // Total Products
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM products");
    $totalProducts = $stmt->fetch()['count'] ?? 0;

    // Latest Orders
    $stmt = $pdo->query("SELECT id, total_amount, status, created_at FROM orders ORDER BY created_at DESC LIMIT 5");
    $latestOrders = $stmt->fetchAll();

    echo json_encode([
        'success' => true,
        'stats' => [
            'revenue' => number_format($revenue, 2),
            'orders' => $totalOrders,
            'activeOrders' => $activeOrders,
            'deliveries' => $deliveries,
            'newUsers' => $newUsers,
            'totalProducts' => $totalProducts,
            'rating' => '4.8'
        ],
        'recentOrders' => $latestOrders
    ]);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
