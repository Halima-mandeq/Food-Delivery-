<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once '../config/db.php';
require_once '../config/auth_roles.php';

ensure_auth_role_support($pdo);

// Check if request is POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method Not Allowed']);
    exit();
}

// Get input data from the request body
$data = json_decode(file_get_contents('php://input'), true);

// Extract individual fields
$email    = $data['email'] ?? '';
$password = $data['password'] ?? '';

// Simple validation
if (empty($email) || empty($password)) {
    http_response_code(400);
    echo json_encode(['error' => 'Email and Password are Required']);
    exit();
}

try {
    // Select user from the database
    $stmt = $pdo->prepare(
        "SELECT id, full_name, email, phone_number, password, role
         FROM users
         WHERE email = ?"
    );
    $stmt->execute([$email]);
    $user = $stmt->fetch();
    
    // Check if user exists and password is correct
    if ($user && password_verify($password, $user['password'])) {
        // Successful login
        http_response_code(200);
        
        // Remove password from response for security
        unset($user['password']);
        
        echo json_encode(['message' => 'Login successful', 'user' => $user]);
    } else {
        // Invalid login details
        http_response_code(401);
        echo json_encode(['error' => 'Invalid email or password']);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to login: ' . $e->getMessage()]);
}
?>
