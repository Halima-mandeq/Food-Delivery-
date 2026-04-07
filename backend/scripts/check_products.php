<?php
require_once '../config/db.php';

try {
    $stmt = $pdo->query("SELECT * FROM products");
    $products = $stmt->fetchAll();
    
    echo "<h1>Products in Database:</h1>";
    echo "<pre>" . json_encode($products, JSON_PRETTY_PRINT) . "</pre>";
} catch (PDOException $e) {
    die("Error: " . $e->getMessage());
}
?>
