<?php
require_once '../config/db.php';

// Default Admin Credentials
$fullName = "Super Admin";
$email    = "admin@foodie.com";
$password = "admin123";
$role     = "admin";

// Check if admin already exists
$stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
$stmt->execute([$email]);
if ($stmt->fetch()) {
    echo "Default Admin ($email) already exists in the database.\n";
    exit();
}

$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

try {
    $stmt = $pdo->prepare("INSERT INTO users (full_name, email, password, role) VALUES (?, ?, ?, ?)");
    $stmt->execute([$fullName, $email, $hashedPassword, $role]);
    
    echo "==========================================\n";
    echo "SUCCESS: Default Admin Created!\n";
    echo "==========================================\n";
    echo "Email:    $email\n";
    echo "Password: $password\n";
    echo "Role:     $role\n";
    echo "==========================================\n";
} catch (PDOException $e) {
    echo "FAILED: " . $e->getMessage() . "\n";
}
?>
