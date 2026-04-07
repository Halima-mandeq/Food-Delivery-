<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

require_once '../config/db.php';

function parse_bool_like($value, $default = 1) {
    if ($value === null || $value === '') {
        return $default;
    }

    $normalized = strtolower(trim((string) $value));
    return in_array($normalized, ['1', 'true', 'yes', 'on', 'active'], true) ? 1 : 0;
}

// Handle multipart/form-data
$name = $_POST['name'] ?? '';
$description = $_POST['description'] ?? '';
$price = $_POST['price'] ?? 0;
$category = $_POST['category'] ?? '';
$image_url = trim($_POST['image_url'] ?? '');
$is_available = parse_bool_like($_POST['is_available'] ?? '1');

if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
    $uploadDir = '../uploads/';
    $fileExtension = pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION);
    $fileName = uniqid() . '.' . $fileExtension;
    $uploadFile = $uploadDir . $fileName;

    if (move_uploaded_file($_FILES['image']['tmp_name'], $uploadFile)) {
        // Store the relative path that the frontend can use
        // Assuming the backend is served from /food delivery/backend/
        $image_url = 'uploads/' . $fileName;
    }
}

if (empty($image_url)) {
    $image_url = 'images/burger.png';
}

if (empty($name) || empty($price)) {
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit;
}

try {
    $stmt = $pdo->prepare(
        "INSERT INTO products (name, description, price, category, image_url, is_available)
         VALUES (?, ?, ?, ?, ?, ?)"
    );
    $stmt->execute([$name, $description, $price, $category, $image_url, $is_available]);
    
    echo json_encode(['success' => true, 'message' => 'Product added successfully']);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>

