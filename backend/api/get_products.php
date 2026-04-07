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
    $category = isset($_GET['category']) ? $_GET['category'] : '';
    $search = isset($_GET['search']) ? $_GET['search'] : '';
    $includeUnavailable = isset($_GET['include_unavailable']) &&
        filter_var($_GET['include_unavailable'], FILTER_VALIDATE_BOOLEAN);
    $featuredOnly = isset($_GET['featured_only']) &&
        filter_var($_GET['featured_only'], FILTER_VALIDATE_BOOLEAN);
    $hasFeaturedOrder = (bool) $pdo
        ->query("SHOW COLUMNS FROM products LIKE 'featured_order'")
        ->fetchColumn();

    $query = "SELECT * FROM products";
    $params = [];
    $conditions = [];

    if (!$includeUnavailable) {
        $conditions[] = "is_available = 1";
    }

    if (!empty($category) && $category !== 'All') {
        $conditions[] = "category = ?";
        $params[] = $category;
    }

    if (!empty($search)) {
        $conditions[] = "(name LIKE ? OR description LIKE ?)";
        $params[] = "%$search%";
        $params[] = "%$search%";
    }

    if ($featuredOnly && $hasFeaturedOrder) {
        $conditions[] = "featured_order IS NOT NULL";
    }

    if (!empty($conditions)) {
        $query .= " WHERE " . implode(" AND ", $conditions);
    }

    if ($featuredOnly && $hasFeaturedOrder) {
        $query .= " ORDER BY 
            CASE WHEN featured_order IS NULL THEN 1 ELSE 0 END,
            featured_order ASC,
            updated_at DESC,
            id DESC";
    } else {
        $query .= " ORDER BY updated_at DESC, id DESC";
    }
    
    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    $products = $stmt->fetchAll();
    echo json_encode($products);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to fetch products: ' . $e->getMessage()]);
}
?>
