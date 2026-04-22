<?php
require_once __DIR__ . '/api/config/database.php';

$db = getDB();

echo "=== BATCHES TABLE SCHEMA ===\n";
$stmt = $db->query('DESCRIBE batches');
$cols = $stmt->fetchAll(PDO::FETCH_ASSOC);
foreach ($cols as $col) {
    echo $col['Field'] . ' - ' . $col['Type'] . ' (' . $col['Null'] . ')' . "\n";
}

echo "\n=== SAMPLE BATCHES DATA ===\n";
$stmt = $db->query('SELECT * FROM batches WHERE DATE(created_at) = CURDATE() LIMIT 5');
$batches = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo "Found " . count($batches) . " batches today\n";
foreach ($batches as $b) {
    echo "ID: {$b['batch_id']}, Status: {$b['status']}, Count: {$b['current_count']}, Rider: {$b['rider_id']}\n";
}

echo "\n=== CLUSTERS TABLE ===\n";
$stmt = $db->query('SELECT cluster_id, barangay_name FROM clusters LIMIT 5');
$clusters = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo "Found " . count($clusters) . " clusters\n";
foreach ($clusters as $c) {
    echo "ID: {$c['cluster_id']}, Name: {$c['barangay_name']}\n";
}
?>
