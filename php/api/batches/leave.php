<?php
// kumpra/api/batches/leave.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$userId  = validateToken();
$body    = getRequestBody();
$batchId = (int)($body['batch_id'] ?? 0);

$db = getDB();
$userIdColumn = getUsersIdColumn($db);

if ($batchId <= 0) {
    $stmt = $db->prepare('SELECT o.batch_id FROM orders o JOIN batches b ON o.batch_id = b.batch_id WHERE o.user_id = ? AND b.status IN ("Gathering", "Last_Call", "Locked") LIMIT 1');
    $stmt->execute([$userId]);
    $existing = $stmt->fetch();
    if (!$existing) {
        respond(['success' => false, 'message' => 'You have not joined any active batch']);
    }
    $batchId = (int)$existing['batch_id'];
}

// Fetch batch
$stmt = $db->prepare('SELECT * FROM batches WHERE batch_id = ? FOR UPDATE');
$stmt->execute([$batchId]);
$batch = $stmt->fetch();

if (!$batch) {
    respond(['success' => false, 'message' => 'Batch not found']);
}

// Check if user has an order in this batch
$stmt = $db->prepare('SELECT order_id FROM orders WHERE user_id = ? AND batch_id = ?');
$stmt->execute([$userId, $batchId]);
$order = $stmt->fetch();

$db->beginTransaction();
try {
    if ($order) {
        $orderId = $order['order_id'];
        $db->prepare('DELETE FROM order_items WHERE order_id = ?')->execute([$orderId]);
        $db->prepare('DELETE FROM orders WHERE order_id = ?')->execute([$orderId]);
    }

    // Decrement batch count even if no order existed
    $newCount = max(0, (int)$batch['current_count'] - 1);
    $newStatus = $batch['status'];

    if (in_array($batch['status'], ['Locked', 'Last_Call']) && $newCount < 3) {
        $newStatus = 'Gathering';
    }

    $db->prepare('UPDATE batches SET current_count = ?, status = ? WHERE batch_id = ?')
       ->execute([$newCount, $newStatus, $batchId]);

    $db->commit();
} catch (Exception $e) {
    $db->rollBack();
    respond(['success' => false, 'message' => 'Failed to leave batch: ' . $e->getMessage()]);
}

respond([
    'success'     => true,
    'message'     => 'Successfully left batch',
    'batch_id'    => $batchId,
    'new_count'   => $newCount,
    'new_status'  => $newStatus,
]);
