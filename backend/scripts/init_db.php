<?php
$host = 'localhost';
$user = 'root';
$pass = '';

try {
    $pdo = new PDO("mysql:host=$host", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Create database if it doesn't exist
    $pdo->exec("CREATE DATABASE IF NOT EXISTS food_delivery_db");
    
    // Select the database
    $pdo->exec("USE food_delivery_db");
    
    // Read and execute schema.sql
    $sql = file_get_contents('../schema.sql');
    $pdo->exec($sql);
    
    echo "<h1>Database Initialized Successfully!</h1>";
    echo "<p>Database 'food_delivery_db' and tables are ready.</p>";
} catch (PDOException $e) {
    die("Error initializing database: " . $e->getMessage());
}
?>
