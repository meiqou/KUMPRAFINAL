<?php
// kumpra/api/riders/location/update.php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$riderId = validateToken();
$data = getRequestBody();
$batchId = (int)($data['batch_id'] ?? 0);
$lat = (float)($data['latitude'] ?? 0);
$lng = (float)($data['longitude'] ?? 0);

if ($batchId <= 0 || $lat == 0 || $lng == 0) {
    respond(['success' => false, 'message' => 'Valid batch_id, latitude, longitude required'], 400);
}

$db = getDB();
$riderIdColumn = getRidersIdColumn($db);

// Verify rider owns batch
$stmt = $db->prepare('SELECT 1 FROM batches WHERE batch_id = ? AND rider_id = ?');
$stmt->execute([$batchId, $riderId]);
if (!$stmt->fetch()) {
    respond(['success' => false, 'message' => 'Not authorized for this batch'], 403);
}

// Update location
$stmt = $db->prepare('UPDATE batches SET rider_latitude = ?, rider_longitude = ?, rider_updated_at = NOW() WHERE batch_id = ?');
$stmt->execute([$lat, $lng, $batchId]);

respond(['success' => true, 'message' => 'Location updated', 'batch_id' => $batchId]);
?>

