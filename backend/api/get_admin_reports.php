<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

$requestMethod = $_SERVER['REQUEST_METHOD'] ?? 'GET';
if ($requestMethod === 'OPTIONS') {
    exit;
}

require_once '../config/db.php';
require_once '../config/order_support.php';

function growthPercent(float $current, float $previous): float
{
    if ($previous > 0) {
        return round((($current - $previous) / $previous) * 100, 1);
    }

    if ($current > 0) {
        return 100.0;
    }

    return 0.0;
}

try {
    ensure_order_support($pdo);

    $summary = $pdo->query(
        "SELECT
            COALESCE(SUM(CASE
                WHEN status = 'Completed'
                 AND DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                THEN total_amount
                ELSE 0
            END), 0) AS total_revenue,
            COALESCE(AVG(CASE
                WHEN DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                THEN total_amount
                ELSE NULL
            END), 0) AS average_order,
            COALESCE(SUM(CASE
                WHEN status = 'Completed'
                 AND DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                THEN 1
                ELSE 0
            END), 0) AS completed_orders,
            COALESCE(SUM(CASE
                WHEN DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                THEN 1
                ELSE 0
            END), 0) AS total_orders,
            COALESCE(SUM(CASE
                WHEN status = 'Completed'
                 AND DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
                 AND DATE(created_at) < DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                THEN total_amount
                ELSE 0
            END), 0) AS previous_revenue
         FROM orders"
    )->fetch();

    $customerStats = $pdo->query(
        "SELECT
            COALESCE(SUM(CASE
                WHEN role <> 'admin'
                THEN 1
                ELSE 0
            END), 0) AS customer_count,
            COALESCE(SUM(CASE
                WHEN role <> 'admin'
                 AND DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                THEN 1
                ELSE 0
            END), 0) AS new_customers,
            COALESCE(SUM(CASE
                WHEN role <> 'admin'
                 AND DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
                 AND DATE(created_at) < DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                THEN 1
                ELSE 0
            END), 0) AS previous_customers
         FROM users"
    )->fetch();

    $trendRows = $pdo->query(
        "SELECT DATE(created_at) AS revenue_date,
                COALESCE(SUM(CASE
                    WHEN status = 'Completed'
                    THEN total_amount
                    ELSE 0
                END), 0) AS revenue
         FROM orders
         WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
         GROUP BY DATE(created_at)"
    )->fetchAll();

    $trendLookup = [];
    foreach ($trendRows as $row) {
        $trendLookup[$row['revenue_date']] = (float) $row['revenue'];
    }

    $weeklyRevenue = [];
    for ($offset = 6; $offset >= 0; $offset--) {
        $date = new DateTime("-{$offset} days");
        $dateKey = $date->format('Y-m-d');
        $weeklyRevenue[] = [
            'label' => strtoupper($date->format('D')),
            'date' => $dateKey,
            'amount' => number_format($trendLookup[$dateKey] ?? 0, 2, '.', ''),
        ];
    }

    $categoryRows = $pdo->query(
        "SELECT UPPER(COALESCE(NULLIF(TRIM(category), ''), 'OTHER')) AS label,
                COUNT(*) AS total
         FROM products
         GROUP BY label
         ORDER BY total DESC, label ASC
         LIMIT 4"
    )->fetchAll();

    $categoryTotal = array_reduce(
        $categoryRows,
        function ($carry, $row) {
            return $carry + (int) $row['total'];
        },
        0
    );

    $categories = array_map(
        function ($row) use ($categoryTotal) {
            $count = (int) $row['total'];
            $percentage = $categoryTotal > 0
                ? (int) round(($count / $categoryTotal) * 100)
                : 0;

            return [
                'label' => $row['label'],
                'count' => $count,
                'percentage' => $percentage,
            ];
        },
        $categoryRows
    );

    $vendorRows = $pdo->query(
        "SELECT p.id,
                p.name,
                p.category,
                p.image_url,
                p.price,
                p.rating,
                p.is_available,
                COALESCE(stats.total_orders, 0) AS total_orders,
                COALESCE(stats.total_amount, 0) AS total_amount
         FROM products p
         LEFT JOIN (
             SELECT restaurant_id,
                    COUNT(*) AS total_orders,
                    SUM(total_amount) AS total_amount
             FROM orders
             WHERE restaurant_id IS NOT NULL
             GROUP BY restaurant_id
         ) stats ON stats.restaurant_id = p.id
         ORDER BY total_orders DESC, p.rating DESC, p.created_at DESC
         LIMIT 3"
    )->fetchAll();

    $vendors = array_map(function ($row) {
        $totalOrders = (int) $row['total_orders'];
        $rating = (float) $row['rating'];
        $isAvailable = (bool) $row['is_available'];

        if ($totalOrders > 0) {
            $status = $isAvailable ? 'live' : 'paused';
            $metric = $totalOrders . ' orders tracked';
        } elseif ($rating >= 4.8) {
            $status = 'top_rated';
            $metric = number_format($rating, 1) . ' rating';
        } else {
            $status = $isAvailable ? 'stable' : 'paused';
            $metric = strtoupper(trim($row['category'] ?: 'OTHER'));
        }

        return [
            'id' => (int) $row['id'],
            'name' => $row['name'],
            'category' => trim($row['category'] ?: 'Other'),
            'image_url' => $row['image_url'] ?? '',
            'rating' => number_format($rating, 1, '.', ''),
            'total_orders' => $totalOrders,
            'amount' => number_format((float) $row['total_amount'], 2, '.', ''),
            'metric' => $metric,
            'status' => $status,
        ];
    }, $vendorRows);

    $currentRevenue = (float) ($summary['total_revenue'] ?? 0);
    $previousRevenue = (float) ($summary['previous_revenue'] ?? 0);
    $newCustomers = (float) ($customerStats['new_customers'] ?? 0);
    $previousCustomers = (float) ($customerStats['previous_customers'] ?? 0);

    echo json_encode([
        'success' => true,
        'summary' => [
            'total_revenue' => number_format($currentRevenue, 2, '.', ''),
            'average_order' => number_format((float) ($summary['average_order'] ?? 0), 2, '.', ''),
            'completed_orders' => (int) ($summary['completed_orders'] ?? 0),
            'total_orders' => (int) ($summary['total_orders'] ?? 0),
            'customer_count' => (int) ($customerStats['customer_count'] ?? 0),
            'new_customers' => (int) $newCustomers,
            'revenue_growth_percent' => growthPercent($currentRevenue, $previousRevenue),
            'customer_growth_percent' => growthPercent($newCustomers, $previousCustomers),
        ],
        'weekly_revenue' => $weeklyRevenue,
        'categories' => $categories,
        'vendors' => $vendors,
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Failed to fetch admin reports: ' . $e->getMessage(),
    ]);
}
?>
