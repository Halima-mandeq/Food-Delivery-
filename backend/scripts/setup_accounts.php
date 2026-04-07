<?php
require_once '../config/db.php';

function createAccount($pdo, $name, $email, $password, $role) {
    // Check if user already exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        echo "Account ($email) already exists.\n";
        return;
    }

    $hashedPassword = password_hash($password, PASSWORD_BCRYPT);

    try {
        $stmt = $pdo->prepare("INSERT INTO users (full_name, email, password, role) VALUES (?, ?, ?, ?)");
        $stmt->execute([$name, $email, $hashedPassword, $role]);
        
        echo "------------------------------------------\n";
        echo "SUCCESS: $role Account Created!\n";
        echo "Email:    $email\n";
        echo "Password: $password\n";
        echo "------------------------------------------\n";
    } catch (PDOException $e) {
        echo "FAILED for $email: " . $e->getMessage() . "\n";
    }
}

echo "<pre>";
echo "🚀 FoodDash System Setup\n";
echo "==========================================\n";

// Create Default Admin
createAccount($pdo, "System Admin", "admin@foodie.com", "admin123", "admin");

// Create Default Customer
createAccount($pdo, "John Doe (Customer)", "user@foodie.com", "user123", "user");

echo "==========================================\n";
echo "Done!\n";
echo "</pre>";
?>
