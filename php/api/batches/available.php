<?php
// kumpra/api/riders/batches/available.php - Open batches for riders
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$riderId = validateToken(); // Rider JWT

$db = getDB();
 $clusterId = (int)($_GET['cluster_id'] ?? 0);
  // Optional: if no cluster_id, show all open batches

// Available: Gathering/Last_Call/Locked (no rider or In_Transit incomplete)
$stmt = $db->prepare("
    SELECT 
        b.batch_id, b.status, b.current_count, b.size_limit, b.cluster_id,
        b.created_at, c.barangay_name, 
        CASE WHEN b.rider_id = ? THEN 'assigned' ELSE 'open' END as rider_status
    FROM batches b 
    JOIN clusters c ON b.cluster_id = c.cluster_id 
    WHERE b.cluster_id = ? 
      AND b.status NOT IN ('Completed', 'Cancelled', 'In_Progress')
      AND DATE(b.created_at) = CURDATE()
    ORDER BY b.created_at DESC
");
$stmt->execute([$riderId, $clusterId]);
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

