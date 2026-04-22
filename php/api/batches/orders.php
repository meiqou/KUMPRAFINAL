<?php
// kumpra/api/batches/orders.php - Get orders/customers for a batch (for rider)
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$riderId = validateToken();
$batchId = (int)($_GET['batch_id'] ?? 0);

if ($batchId <= 0) {
    respond(['success' => false, 'message' => 'batch_id required'], 400);
}

$db = getDB();

// Verify rider owns the batch
$stmt = $db->prepare('SELECT cluster_id FROM batches WHERE batch_id = ? AND rider_id = ?');
$stmt->execute([$batchId, $riderId]);
$batch = $stmt->fetch();
if (!$batch) {
    respond(['success' => false, 'message' => 'Batch not found or not yours'], 403);
}

$clusterId = $batch['cluster_id'];

// Get cluster coords for customers (assuming customers at cluster pickup)
$stmt = $db->prepare('SELECT latitude, longitude FROM clusters WHERE cluster_id = ?');
$stmt->execute([$clusterId]);
$cluster = $stmt->fetch();

// Get orders
$stmt = $db->prepare('
    SELECT o.order_id, o.status, o.estimated_total, 
           u.name, u.phone 
    FROM orders o 
    JOIN users u ON o.user_id = u.user_id 
    WHERE o.batch_id = ?
    ORDER BY o.created_at ASC
');
$stmt->execute([$batchId]);
$orders = $stmt->fetchAll();

$customers = [];
foreach ($orders as $order) {
    $customers[] = [
        'order_id' => (int)$order['order_id'],
        'name' => $order['name'],
        'phone' => $order['phone'],
        'status' => $order['status'],
        'estimated_total' => (float)$order['estimated_total'],
        'latitude' => $cluster['latitude'], // Pickup at cluster
        'longitude' => $cluster['longitude'],
        'created_at' => $order['created_at'] ?? ''
    ];
}

respond(['success' => true, 'customers' => $customers, 'cluster' => $cluster]);
?>

