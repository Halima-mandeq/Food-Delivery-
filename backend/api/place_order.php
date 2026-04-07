<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once '../config/db.php';
require_once '../config/order_support.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method Not Allowed']);
    exit();
}

$payload = json_decode(file_get_contents('php://input'), true);

$userId = (int) ($payload['user_id'] ?? 0);
$restaurant = is_array($payload['restaurant'] ?? null)
    ? $payload['restaurant']
    : [];
$items = is_array($payload['items'] ?? null)
    ? $payload['items']
    : [];
$deliveryAddress = trim((string) ($payload['delivery_address'] ?? ''));
$deliveryFee = round((float) ($payload['delivery_fee'] ?? 0), 2);
$taxAmount = round((float) ($payload['tax_amount'] ?? 0), 2);
$paymentMethod = normalize_payment_method($payload['payment_method'] ?? null);
$estimatedDeliveryTime = normalize_delivery_time(
    $payload['estimated_delivery_time'] ?? ($restaurant['delivery_time'] ?? null)
);

if ($userId <= 0) {
    http_response_code(400);
    echo json_encode(['error' => 'A valid user is required.']);
    exit();
}

if (empty($restaurant)) {
    http_response_code(400);
    echo json_encode(['error' => 'Restaurant details are required.']);
    exit();
}

if ($deliveryAddress === '') {
    http_response_code(400);
    echo json_encode(['error' => 'Delivery address is required.']);
    exit();
}

if (empty($items)) {
    http_response_code(400);
    echo json_encode(['error' => 'Add at least one item before placing the order.']);
    exit();
}

try {
    ensure_order_support($pdo);

    $userStmt = $pdo->prepare("SELECT EXISTS(SELECT 1 FROM users WHERE id = ?)");
    $userStmt->execute([$userId]);
    if (!(bool) $userStmt->fetchColumn()) {
        http_response_code(404);
        echo json_encode(['error' => 'The selected user account was not found.']);
        exit();
    }

    $normalizedItems = [];
    $subtotalAmount = 0.0;

    foreach ($items as $rawItem) {
        if (!is_array($rawItem)) {
            continue;
        }

        $quantity = max(1, (int) ($rawItem['quantity'] ?? 0));
        $unitPrice = round((float) ($rawItem['unit_price'] ?? 0), 2);
        $name = trim((string) ($rawItem['name'] ?? ''));

        if ($name === '' || $unitPrice <= 0) {
            continue;
        }

        $normalizedItems[] = [
            'menu_item_id' => isset($rawItem['menu_item_id'])
                ? (int) $rawItem['menu_item_id']
                : null,
            'name' => $name,
            'image_url' => trim((string) ($rawItem['image_url'] ?? '')),
            'notes' => trim((string) ($rawItem['notes'] ?? '')),
            'options' => is_array($rawItem['selected_options'] ?? null)
                ? array_values($rawItem['selected_options'])
                : [],
            'quantity' => $quantity,
            'unit_price' => $unitPrice,
        ];

        $subtotalAmount += $quantity * $unitPrice;
    }

    if (empty($normalizedItems)) {
        http_response_code(400);
        echo json_encode(['error' => 'No valid order items were provided.']);
        exit();
    }

    $subtotalAmount = round($subtotalAmount, 2);
    $totalAmount = round($subtotalAmount + $deliveryFee + $taxAmount, 2);

    $pdo->beginTransaction();

    $orderStmt = $pdo->prepare(
        "INSERT INTO orders (
            user_id,
            restaurant_id,
            restaurant_name,
            restaurant_image_url,
            total_amount,
            subtotal_amount,
            delivery_fee,
            tax_amount,
            payment_method,
            status,
            delivery_address,
            estimated_delivery_time
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending', ?, ?)"
    );

    $orderStmt->execute([
        $userId,
        isset($restaurant['id']) ? (int) $restaurant['id'] : null,
        trim((string) ($restaurant['name'] ?? 'Restaurant')),
        trim((string) ($restaurant['image_url'] ?? '')),
        $totalAmount,
        $subtotalAmount,
        $deliveryFee,
        $taxAmount,
        $paymentMethod,
        $deliveryAddress,
        $estimatedDeliveryTime,
    ]);

    $orderId = (int) $pdo->lastInsertId();

    $itemStmt = $pdo->prepare(
        "INSERT INTO order_items (
            order_id,
            product_id,
            menu_item_id,
            item_name,
            item_image_url,
            item_notes,
            item_options,
            quantity,
            price
        ) VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?)"
    );

    foreach ($normalizedItems as $item) {
        $itemStmt->execute([
            $orderId,
            $item['menu_item_id'],
            $item['name'],
            $item['image_url'],
            $item['notes'],
            json_encode($item['options']),
            $item['quantity'],
            $item['unit_price'],
        ]);
    }

    $pdo->commit();

    $orders = fetch_orders_for_user($pdo, $userId, $orderId);
    $order = $orders[0] ?? null;

    echo json_encode([
        'success' => true,
        'order' => $order,
    ]);
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }

    http_response_code(500);
    echo json_encode([
        'error' => 'Failed to place order: ' . $e->getMessage(),
    ]);
}
?>
