<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../config/db.php';

$restaurant_id = isset($_GET['restaurant_id']) ? $_GET['restaurant_id'] : null;

if (!$restaurant_id) {
    http_response_code(400);
    echo json_encode(["error" => "Restaurant ID is required"]);
    exit();
}

try {
    $stmt = $pdo->prepare("SELECT * FROM menu_items WHERE restaurant_id = ?");
    $stmt->execute([$restaurant_id]);
    $menu_items = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode($menu_items);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Database error: " . $e->getMessage()]);
}
?>
