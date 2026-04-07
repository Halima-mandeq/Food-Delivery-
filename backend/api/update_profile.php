<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once '../config/db.php';
require_once '../config/auth_roles.php';

ensure_auth_role_support($pdo);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method Not Allowed']);
    exit();
}

$data = json_decode(file_get_contents('php://input'), true);
if (!is_array($data)) {
    $data = [];
}

$userId = isset($data['user_id']) ? (int) $data['user_id'] : 0;
$fullName = trim((string) ($data['full_name'] ?? ''));
$email = trim((string) ($data['email'] ?? ''));
$phoneNumber = trim((string) ($data['phone_number'] ?? ''));
$currentPassword = (string) ($data['current_password'] ?? '');
$newPassword = (string) ($data['new_password'] ?? '');

if ($userId <= 0 || $fullName === '' || $email === '') {
    http_response_code(400);
    echo json_encode(['error' => 'User ID, full name, and email are required']);
    exit();
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['error' => 'Enter a valid email address']);
    exit();
}

try {
    $stmt = $pdo->prepare(
        "SELECT id, full_name, email, phone_number, password, role
         FROM users
         WHERE id = ?"
    );
    $stmt->execute([$userId]);
    $user = $stmt->fetch();

    if (!$user) {
        http_response_code(404);
        echo json_encode(['error' => 'User not found']);
        exit();
    }

    $emailChanged = strcasecmp($user['email'], $email) !== 0;
    $passwordChanged = $newPassword !== '';

    if ($emailChanged || $passwordChanged) {
        if ($currentPassword === '') {
            http_response_code(400);
            echo json_encode([
                'error' => 'Current password is required to change email or password',
            ]);
            exit();
        }

        if (!password_verify($currentPassword, $user['password'])) {
            http_response_code(401);
            echo json_encode(['error' => 'Current password is incorrect']);
            exit();
        }
    }

    if ($passwordChanged && strlen($newPassword) < 6) {
        http_response_code(400);
        echo json_encode(['error' => 'New password must be at least 6 characters']);
        exit();
    }

    if ($emailChanged) {
        $emailCheck = $pdo->prepare(
            "SELECT id
             FROM users
             WHERE email = ? AND id <> ?"
        );
        $emailCheck->execute([$email, $userId]);

        if ($emailCheck->fetch()) {
            http_response_code(409);
            echo json_encode(['error' => 'Another account already uses that email']);
            exit();
        }
    }

    $passwordHash = $passwordChanged
        ? password_hash($newPassword, PASSWORD_BCRYPT)
        : $user['password'];
    $normalizedPhone = $phoneNumber === '' ? null : $phoneNumber;

    $update = $pdo->prepare(
        "UPDATE users
         SET full_name = ?,
             email = ?,
             phone_number = ?,
             password = ?
         WHERE id = ?"
    );
    $update->execute([
        $fullName,
        $email,
        $normalizedPhone,
        $passwordHash,
        $userId,
    ]);

    $refresh = $pdo->prepare(
        "SELECT id, full_name, email, phone_number, role
         FROM users
         WHERE id = ?"
    );
    $refresh->execute([$userId]);
    $updatedUser = $refresh->fetch();

    http_response_code(200);
    echo json_encode([
        'message' => 'Profile updated successfully',
        'user' => $updatedUser,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to update profile: ' . $e->getMessage()]);
}
?>
