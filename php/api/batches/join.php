<?php
// kumpra/api/batches/join.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$userId  = validateToken();
$body    = getRequestBody();
$batchId = (int)($body['batch_id'] ?? 0);

if ($batchId <= 0) {
    respond(['success' => false, 'message' => 'batch_id is required']);
}

$db = getDB();
$userIdColumn = getUsersIdColumn($db);

// Fetch batch
$stmt = $db->prepare('SELECT * FROM batches WHERE batch_id = ? FOR UPDATE');
$stmt->execute([$batchId]);
$batch = $stmt->fetch();

if (!$batch) {
    respond(['success' => false, 'message' => 'Batch not found']);
}
if (!in_array($batch['status'], ['Gathering', 'Last_Call'])) {
    respond(['success' => false, 'message' => 'This batch is no longer accepting orders']);
}
if ((int)$batch['current_count'] >= (int)$batch['size_limit']) {
    respond(['success' => false, 'message' => 'This batch is full']);
}

// Check user already joined
$stmt = $db->prepare('SELECT order_id FROM orders WHERE user_id = ? AND batch_id = ?');
$stmt->execute([$userId, $batchId]);
if ($stmt->fetch()) {
    respond(['success' => false, 'message' => 'You have already joined this batch']);
}

// Check user is in correct cluster
$stmt = $db->prepare('SELECT cluster_id FROM users WHERE ' . $userIdColumn . ' = ?');
$stmt->execute([$userId]);
$user = $stmt->fetch();
if ((int)$user['cluster_id'] !== (int)$batch['cluster_id']) {
    respond(['success' => false, 'message' => 'This batch is not in your cluster']);
}

// All good — respond success (order created when basket is submitted)
$newCount = (int)$batch['current_count'] + 1;

// Determine if we need to trigger departure-ready status
$db->beginTransaction();
try {
    $newStatus = $batch['status'];
    if ($newCount >= 3 && $batch['status'] === 'Gathering') {
        $newStatus = 'Locked';
        $db->prepare('UPDATE batches SET status = ?, current_count = ? WHERE batch_id = ?')
           ->execute([$newStatus, $newCount, $batchId]);
    } else {
        $db->prepare('UPDATE batches SET current_count = ? WHERE batch_id = ?')
           ->execute([$newCount, $batchId]);
    }
    $db->commit();
} catch (Exception $e) {
    $db->rollBack();
    respond(['success' => false, 'message' => 'Failed to join batch']);
}

respond([
    'success'     => true,
    'message'     => 'Successfully joined batch',
    'batch_id'    => $batchId,
    'new_status'  => $newStatus,
    'new_count'   => $newCount,
]);
