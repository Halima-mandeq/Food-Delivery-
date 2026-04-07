<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

try {
    // 1. Try connecting without a specific DB first to see if MySQL is alive
    $host = 'localhost';
    $user = 'root';
    $pass = '';
    $pdo = new PDO("mysql:host=$host", $user, $pass);
    echo "Connection to MySQL: SUCCESS\n";

    // 2. Check if database exists
    $stmt = $pdo->query("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'food_delivery_db'");
    if ($stmt->fetch()) {
        echo "Database 'food_delivery_db': EXISTS\n";
    } else {
        echo "Database 'food_delivery_db': MISSING\n";
        // Create it
        $pdo->exec("CREATE DATABASE food_delivery_db");
        echo "Database 'food_delivery_db': CREATED\n";
    }

    // 3. Connect to the DB
    $pdo->exec("USE food_delivery_db");

    // 4. Check if users table exists
    $stmt = $pdo->query("SHOW TABLES LIKE 'users'");
    if ($stmt->fetch()) {
        echo "Table 'users': EXISTS\n";
    } else {
        echo "Table 'users': MISSING\n";
        // Create it
        $sql = file_get_contents('c:/xampp/htdocs/food delivery/backend/schema.sql');
        $pdo->exec($sql);
        echo "Table 'users': CREATED (from schema.sql)\n";
    }

    // 5. Check for the admin user
    $stmt = $pdo->prepare("SELECT email FROM users WHERE email = ?");
    $stmt->execute(['admin@gmail.com']);
    if ($stmt->fetch()) {
        echo "Admin 'admin@gmail.com': FOUND\n";
    } else {
        echo "Admin 'admin@gmail.com': NOT FOUND. Adding now...\n";
        $hashed = password_hash('admin123', PASSWORD_BCRYPT);
        $stmt = $pdo->prepare("INSERT INTO users (full_name, email, password, role) VALUES ('Super Admin', 'admin@gmail.com', ?, 'admin')");
        $stmt->execute([$hashed]);
        echo "Admin 'admin@gmail.com': ADDED\n";
    }

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
?>
