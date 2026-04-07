<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

require_once '../config/db.php';

try {
    $categoriesTableExists = $pdo->query("SHOW TABLES LIKE 'categories'")
        ->fetchColumn();
    $hasDisplayOrder = false;

    if ($categoriesTableExists) {
        $hasDisplayOrder = (bool) $pdo
            ->query("SHOW COLUMNS FROM categories LIKE 'display_order'")
            ->fetchColumn();
    }

    $tableCategories = [];
    if ($categoriesTableExists) {
        $categoryQuery = $hasDisplayOrder
            ? "SELECT name FROM categories ORDER BY display_order ASC, name ASC"
            : "SELECT name FROM categories ORDER BY name ASC";

        $tableCategories = $pdo->query($categoryQuery)
            ->fetchAll(PDO::FETCH_COLUMN);
    }

    $productCategories = $pdo->query(
        "SELECT DISTINCT category
         FROM products
         WHERE is_available = 1
           AND category IS NOT NULL
           AND TRIM(category) <> ''"
    )->fetchAll(PDO::FETCH_COLUMN);

    $normalizedTableCategories = array_map('mb_strtolower', $tableCategories);
    $extraCategories = [];

    foreach ($productCategories as $category) {
        $normalizedCategory = mb_strtolower(trim($category));
        if ($normalizedCategory === '' ||
            in_array($normalizedCategory, $normalizedTableCategories, true)) {
            continue;
        }

        $extraCategories[] = $category;
    }

    natcasesort($extraCategories);

    $categories = array_values(array_merge(
        $tableCategories,
        array_values(array_unique($extraCategories))
    ));

    echo json_encode($categories);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
