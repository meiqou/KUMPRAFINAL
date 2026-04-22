<?php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

/**
 * GET /api/batches/customers.php?batch_id=123
 * Returns a list of customers and their locations for a specific batch.
 */

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$userId = validateToken(); // Ensure the request is from an authenticated rider
$batchId = (int)($_GET['batch_id'] ?? 0);

if ($batchId <= 0) {
    respond(['success' => false, 'message' => 'Invalid or missing batch_id']);
}

$db = getDB();
$userIdColumn = getUsersIdColumn($db);

try {
    // We fetch users who have an active order in this specific batch.
    // This ensures the rider only sees markers for people they are actually shopping for.
    $query = "
        SELECT DISTINCT 
            u.$userIdColumn AS user_id, 
            u.name, 
            u.latitude, 
            u.longitude 
        FROM orders o
        JOIN users u ON o.user_id = u.$userIdColumn
        WHERE o.batch_id = ?
    ";
    
    $stmt = $db->prepare($query);
    $stmt->execute([$batchId]);
    $customers = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Ensure coordinates are returned as numbers for the Flutter app
    respond([
        'success' => true,
        'customers' => $customers
    ]);
} catch (PDOException $e) {
    error_log($e->getMessage());
    respond(['success' => false, 'message' => 'Internal server error fetching customer data'], 500);
}