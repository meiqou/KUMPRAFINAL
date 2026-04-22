<?php
// kumpra/api/riders/batches/available.php - Open batches for riders
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$riderId = validateToken(); // Rider JWT

$db = getDB();
$clusterId = (int)($_GET['cluster_id'] ?? 0);
// Optional filter by cluster; if 0, show all open batches across clusters

// Available: Gathering/Last_Call/Locked (not yet assigned to a rider or already in progress)
$sql = "
    SELECT 
        b.batch_id, b.status, b.current_count, b.size_limit, b.cluster_id,
        b.created_at, c.barangay_name, 
        CASE WHEN b.rider_id IS NOT NULL THEN 'assigned' ELSE 'open' END as rider_status
    FROM batches b 
    JOIN clusters c ON b.cluster_id = c.cluster_id 
    WHERE b.status IN ('Gathering', 'Last_Call', 'Locked')
      AND (b.rider_id IS NULL OR b.rider_id = 0)
      AND DATE(b.created_at) = CURDATE()
";
$params = [];

if ($clusterId > 0) {
    $sql .= " AND b.cluster_id = ? ";
    $params[] = $clusterId;
}

$sql .= " ORDER BY b.created_at DESC";

$stmt = $db->prepare($sql);
$stmt->execute($params);
$batches = $stmt->fetchAll();

  $formatted = array_map(function($b) {
    $fee = $b['current_count'] > 0 ? 300 / max($b['current_count'], 1) : 300;
    return [
        'batch_id' => (int)$b['batch_id'],
        'name' => strtoupper($b['barangay_name']) . '-' . $b['batch_id'],
        'cluster_name' => $b['barangay_name'],
        'status' => $b['status'],
        'joined' => (int)$b['current_count'],
        'size_limit' => (int)$b['size_limit'],
        'shared_fee' => round($fee, 2),
        'rider_status' => $b['rider_status'],
        'created_at' => $b['created_at']
    ];
}, $batches);

respond(['success' => true, 'batches' => $formatted]);
?>

