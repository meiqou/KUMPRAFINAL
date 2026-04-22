<?php
// kumpra/api/orders/status.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$userId  = validateToken();
$orderId = (int)($_GET['order_id'] ?? 0);

if ($orderId <= 0) respond(['success' => false, 'message' => 'order_id is required']);

$db = getDB();

$hasRiderLatitude = hasTableColumn($db, 'riders', 'latitude');
$hasRiderLongitude = hasTableColumn($db, 'riders', 'longitude');
$riderLatitudeSelect = $hasRiderLatitude ? 'r.latitude AS rider_latitude' : 'NULL AS rider_latitude';
$riderLongitudeSelect = $hasRiderLongitude ? 'r.longitude AS rider_longitude' : 'NULL AS rider_longitude';

$stmt = $db->prepare(" 
    SELECT 
        o.order_id,
        o.status AS order_status,
        o.estimated_total,
        o.actual_final_total,
        o.payment_status,
        o.created_at,
        o.delivered_at,
        b.batch_id,
        b.status AS batch_status,
        c.barangay_name,
        c.street_zone,
        c.latitude,
        c.longitude,
        r.name AS rider_name,
        $riderLatitudeSelect,
        $riderLongitudeSelect,
        r.plate_number
    FROM orders o
    JOIN batches b ON o.batch_id = b.batch_id
    JOIN clusters c ON b.cluster_id = c.cluster_id
    LEFT JOIN riders r ON b.rider_id = r.rider_id
    WHERE o.order_id = ? AND o.user_id = ?
    ");
$stmt->execute([$orderId, $userId]);
$order = $stmt->fetch();

if (!$order) {
    respond(['success' => false, 'message' => 'Order not found'], 404);
}

// Get items
$stmt = $db->prepare('SELECT * FROM order_items WHERE order_id = ?');
$stmt->execute([$orderId]);
$order['items'] = $stmt->fetchAll();
$order['estimated_total'] = (float)$order['estimated_total'];
$order['actual_final_total'] = (float)$order['actual_final_total'];

// Map batch status to progress step
$progressMap = [
    'Gathering'  => 0,
    'Last_Call'  => 0,
    'Locked'     => 0,
    'Purchasing' => 1,
    'In_Transit' => 3,
    'Completed'  => 4,
];
$order['market_progress'] = $progressMap[$order['batch_status']] ?? 0;

respond(['success' => true, 'order' => $order]);
