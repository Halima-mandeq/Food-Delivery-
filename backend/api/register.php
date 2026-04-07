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
$fullName = $data['full_name'] ?? '';
$email    = $data['email'] ?? '';
$phone    = $data['phone_number'] ?? '';
$password = $data['password'] ?? '';
$role     = normalize_auth_role($data['role'] ?? 'user');

// Simple validation
if (empty($fullName) || empty($email) || empty($password)) {
    http_response_code(400);
    echo json_encode(['error' => 'Full Name, Email, and Password are Required']);
    exit();
}

// Check if user already exists
$stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
$stmt->execute([$email]);
if ($stmt->fetch()) {
    http_response_code(409);
    echo json_encode(['error' => 'User with this email already exists']);
    exit();
}

// Hash the password securely
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

try {
    // Insert new user into the database
    $stmt = $pdo->prepare("INSERT INTO users (full_name, email, phone_number, password, role) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$fullName, $email, $phone, $hashedPassword, $role]);
    
    // Return success message
    http_response_code(201);
    echo json_encode(['message' => 'User registered successfully!', 'role' => $role]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to register user: ' . $e->getMessage()]);
}
?>
