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
    $tableExists = $pdo->query("SHOW TABLES LIKE 'home_promotions'")
        ->fetchColumn();

    if (!$tableExists) {
        echo json_encode([]);
        exit;
    }

    $stmt = $pdo->query(
        "SELECT id, kind, title, subtitle, cta_label, icon_key
         FROM home_promotions
         WHERE is_active = 1
         ORDER BY display_order ASC, id ASC"
    );

    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Failed to fetch home promotions: ' . $e->getMessage(),
    ]);
}
?>
