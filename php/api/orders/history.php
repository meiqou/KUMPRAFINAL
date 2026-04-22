<?php
// kumpra/api/orders/history.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$userId = validateToken();
$db = getDB();

$stmt = $db->prepare('
    SELECT 
        o.order_id,
        o.status,
        o.estimated_total,
        o.actual_final_total,
        o.payment_status,
        o.created_at,
        o.delivered_at,
        b.batch_id,
        c.barangay_name,
        c.street_zone,
        r.name AS rider_name
    FROM orders o
    JOIN batches b ON o.batch_id = b.batch_id
    JOIN clusters c ON b.cluster_id = c.cluster_id
    LEFT JOIN riders r ON b.rider_id = r.rider_id
    WHERE o.user_id = ?
    ORDER BY o.created_at DESC
    LIMIT 20
');
$stmt->execute([$userId]);
$orders = $stmt->fetchAll();

// Attach items to each order
$itemStmt = $db->prepare('SELECT * FROM order_items WHERE order_id = ?');
foreach ($orders as &$order) {
    $itemStmt->execute([$order['order_id']]);
    $order['items'] = $itemStmt->fetchAll();
    $order['estimated_total'] = (float)$order['estimated_total'];
    $order['actual_final_total'] = (float)$order['actual_final_total'];
}

respond(['success' => true, 'orders' => $orders]);
