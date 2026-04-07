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

$id = $_POST['id'] ?? null;
$name = trim($_POST['name'] ?? '');
$description = trim($_POST['description'] ?? '');
$price = $_POST['price'] ?? 0;
$category = trim($_POST['category'] ?? '');
$selected_image_url = trim($_POST['image_url'] ?? '');
$image_url = trim($_POST['existing_image_url'] ?? '');
$raw_is_available = $_POST['is_available'] ?? null;

if (!$id || empty($name) || $price === '') {
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit;
}

try {
    $stmt = $pdo->prepare("SELECT image_url, is_available FROM products WHERE id = ?");
    $stmt->execute([$id]);
    $product = $stmt->fetch();

    if (!$product) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Product not found']);
        exit;
    }

    $oldImage = $product['image_url'] ?? '';

    if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $uploadDir = '../uploads/';
        $fileExtension = pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION);
        $fileName = uniqid() . '.' . $fileExtension;
        $uploadFile = $uploadDir . $fileName;

        if (!move_uploaded_file($_FILES['image']['tmp_name'], $uploadFile)) {
            throw new RuntimeException('Failed to upload image');
        }

        $image_url = 'uploads/' . $fileName;
    } elseif (!empty($selected_image_url)) {
        $image_url = $selected_image_url;
    } elseif (empty($image_url)) {
        $image_url = $oldImage ?: 'images/burger.png';
    }

    $is_available = parse_bool_like($raw_is_available, (int) ($product['is_available'] ?? 1));

    if ($image_url !== $oldImage && str_starts_with($oldImage, 'uploads/')) {
        $oldPath = '../' . $oldImage;
        if (file_exists($oldPath)) {
            unlink($oldPath);
        }
    }

    $stmt = $pdo->prepare(
        "UPDATE products
         SET name = ?, description = ?, price = ?, category = ?, image_url = ?, is_available = ?
         WHERE id = ?"
    );
    $stmt->execute([$name, $description, $price, $category, $image_url, $is_available, $id]);

    echo json_encode(['success' => true, 'message' => 'Product updated successfully']);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
