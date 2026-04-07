<?php
require_once '../config/db.php';

$email = 'admin@gmail.com';
$password = 'admin123';
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

try {
    // Check if user exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if ($user) {
        // Update existing user
        $stmt = $pdo->prepare("UPDATE users SET password = ?, role = 'admin' WHERE email = ?");
        $stmt->execute([$hashedPassword, $email]);
        echo "Admin user ($email) updated successfully!";
    } else {
        // Insert new admin user
        $stmt = $pdo->prepare("INSERT INTO users (full_name, email, password, role) VALUES (?, ?, ?, ?)");
        $stmt->execute(['Super Admin', $email, $hashedPassword, 'admin']);
        echo "Admin user ($email) created successfully!";
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>
