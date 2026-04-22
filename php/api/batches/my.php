<?php
// kumpra/api/batches/my.php - Rider's active batches
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$riderId = validateToken(); // Rider JWT

$db = getDB();

$sql = "
    SELECT 
        b.*, 
        c.barangay_name, c.latitude, c.longitude, c.street_zone,
        (SELECT COUNT(*) FROM orders o WHERE o.batch_id = b.batch_id) as joined_count
    FROM batches b 
    JOIN clusters c ON b.cluster_id = c.cluster_id 
    WHERE b.rider_id = ? 
      AND b.status IN ('In_Progress', 'In_Transit')
      AND DATE(b.created_at) = CURDATE()
    ORDER BY b.updated_at DESC
";

$stmt = $db->prepare($sql);
$stmt->execute([$riderId]);
$batches = $stmt->fetchAll();

$statusMap = [
    'In_Progress' => 'In Progress - To Market',
    'In_Transit' => 'Returning Home',
];

$formatted = array_map(function($b) use ($statusMap) {
    $lat = !empty($b['latitude']) && (float)$b['latitude'] != 0 ? (float)$b['latitude'] : 10.6765;
    $lng = !empty($b['longitude']) && (float)$b['longitude'] != 0 ? (float)$b['longitude'] : 122.9513;
    $fee = $b['joined_count'] > 0 ? round(300 / max($b['joined_count'], 1), 2) : 300.0;

    return [
        'batch_id' => (int)$b['batch_id'],
        'name' => strtoupper($b['barangay_name']) . '-' . $b['batch_id'],
        'cluster_name' => $b['barangay_name'],
        'address' => $b['street_zone'],
        'status' => $statusMap[$b['status']] ?? $b['status'],
        'joined' => (int)$b['joined_count'],
        'size_limit' => (int)$b['size_limit'],
        'shared_fee' => $fee,
        'rider_latitude' => (float)$b['rider_latitude'], // From GPS updates
        'rider_longitude' => (float)$b['rider_longitude'],
        'latitude' => $lat,
        'longitude' => $lng,
        'created_at' => $b['created_at'],
        'updated_at' => $b['updated_at']
    ];
}, $batches);

respond(['success' => true, 'batches' => $formatted]);
?>

