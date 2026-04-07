<?php
require_once '../config/db.php';

function resetAccount($pdo, $name, $email, $password, $role) {
    $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
    try {
        $stmt = $pdo->prepare("DELETE FROM users WHERE email = ?");
        $stmt->execute([$email]);
        
        $stmt = $pdo->prepare("INSERT INTO users (full_name, email, password, role) VALUES (?, ?, ?, ?)");
        $stmt->execute([$name, $email, $hashedPassword, $role]);
        
        echo "✅ Account reset for $email (password: $password)\n";
    } catch (PDOException $e) {
        echo "❌ Error for $email: " . $e->getMessage() . "\n";
    }
}

echo "<pre>";
resetAccount($pdo, "Admin User", "admin@foodie.com", "admin123", "admin");
resetAccount($pdo, "Customer User", "user@foodie.com", "user123", "user");
echo "</pre>";
?>
