<?php
// kumpra/api/orders/create.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$userId = validateToken();
$body   = getRequestBody();

$batchId        = (int)($body['batch_id'] ?? 0);
$estimatedTotal = (float)($body['estimated_total'] ?? 0);
$items          = $body['items'] ?? [];

if ($batchId <= 0) respond(['success' => false, 'message' => 'batch_id is required']);
if (empty($items))  respond(['success' => false, 'message' => 'No items in basket']);

$db = getDB();
$userIdColumn = getUsersIdColumn($db);

// Verify batch is valid and user's cluster matches
$stmt = $db->prepare('
    SELECT b.batch_id, b.status, b.cluster_id, b.load_capacity_kg, b.total_weight
    FROM batches b
    JOIN users u ON u.cluster_id = b.cluster_id
    WHERE b.batch_id = ? AND u.' . $userIdColumn . ' = ?
');
$stmt->execute([$batchId, $userId]);
$batch = $stmt->fetch();

if (!$batch) {
    respond(['success' => false, 'message' => 'Invalid batch or cluster mismatch']);
}
if (!in_array($batch['status'], ['Gathering', 'Last_Call', 'Locked'])) {
    respond(['success' => false, 'message' => 'Batch is not accepting orders right now']);
}

// Check if user already has an order in this batch
$stmt = $db->prepare('SELECT order_id FROM orders WHERE user_id = ? AND batch_id = ?');
$stmt->execute([$userId, $batchId]);
$existing = $stmt->fetch();

$db->beginTransaction();
try {
    if ($existing) {
        // Update existing order
        $orderId = (int)$existing['order_id'];
        $db->prepare('UPDATE orders SET estimated_total = ?, updated_at = NOW() WHERE order_id = ?')
           ->execute([$estimatedTotal, $orderId]);
        // Remove old items
        $db->prepare('DELETE FROM order_items WHERE order_id = ?')->execute([$orderId]);
    } else {
        // Create new order
        $stmt = $db->prepare('
            INSERT INTO orders (user_id, batch_id, status, estimated_total, payment_status, created_at, updated_at)
            VALUES (?, ?, "Pending", ?, "Unpaid", NOW(), NOW())
        ');
        $stmt->execute([$userId, $batchId, $estimatedTotal]);
        $orderId = (int)$db->lastInsertId();
    }

    // Insert items
    $totalWeight = 0.0;
    $insertItem = $db->prepare('
        INSERT INTO order_items (order_id, item_name, quantity, user_est_price, weight_kg)
        VALUES (?, ?, ?, ?, ?)
    ');
    foreach ($items as $item) {
        $weight = (float)($item['weight_kg'] ?? 1.0);
        $totalWeight += $weight;
        $insertItem->execute([
            $orderId,
            $item['item_name'],
            $item['quantity'],
            (float)($item['user_est_price'] ?? 0),
            $weight,
        ]);
    }

    // Update batch total weight
    $db->prepare('UPDATE batches SET total_weight = total_weight + ? WHERE batch_id = ?')
       ->execute([$totalWeight, $batchId]);

    $db->commit();
} catch (Exception $e) {
    $db->rollBack();
    respond(['success' => false, 'message' => 'Failed to create order: ' . $e->getMessage()]);
}

respond([
    'success'  => true,
    'message'  => 'Order submitted successfully',
    'order_id' => $orderId,
]);
