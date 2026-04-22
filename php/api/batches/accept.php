<?php
// kumpra/api/riders/batches/accept.php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$riderId = validateToken();
$data = getRequestBody();
$batchId = (int)($data['batch_id'] ?? 0);

if ($batchId <= 0) {
    respond(['success' => false, 'message' => 'batch_id required'], 400);
}

$db = getDB();
$riderIdColumn = getRidersIdColumn($db);

// Lock batch
$stmt = $db->prepare('SELECT batch_id, status, rider_id FROM batches WHERE batch_id = ? FOR UPDATE');
$stmt->execute([$batchId]);
$batch = $stmt->fetch();

if (!$batch) {
    respond(['success' => false, 'message' => 'Batch not found'], 404);
}
if ($batch['rider_id']) {
    respond(['success' => false, 'message' => 'Batch already accepted'], 400);
}
if (!in_array($batch['status'], ['Gathering', 'Last_Call', 'Locked'])) {
    respond(['success' => false, 'message' => 'Batch no longer available'], 400);
}

// Transaction: Assign rider, update status
$db->beginTransaction();
try {
    $db->prepare('UPDATE batches SET rider_id = ?, status = "In_Progress", updated_at = NOW() WHERE batch_id = ?')
       ->execute([$riderId, $batchId]);
    $db->commit();
    
    respond([
        'success' => true, 
        'message' => 'Batch accepted! Status: In_Progress',
        'batch_id' => $batchId
    ]);
} catch (Exception $e) {
    $db->rollBack();
    respond(['success' => false, 'message' => 'Failed to accept batch'], 500);
}
?>

