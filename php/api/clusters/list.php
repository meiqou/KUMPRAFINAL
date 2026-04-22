<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

// This endpoint will strictly support GET requests for data retrieval.
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respond(['success' => false, 'message' => 'Invalid request method'], 405);
}

try {
    $pdo = getDB();

    /**
     * The query will fetch the cluster data.
     * We will alias 'barangay_name' to 'name' so it matches your UI dropdown expectations.
     */
    $sql = "SELECT 
                cluster_id, 
                barangay_name AS name, 
                street_zone 
            FROM clusters 
            ORDER BY barangay_name ASC";

    $stmt = $pdo->query($sql);

    // We will use FETCH_ASSOC to get a clean array without numeric duplicates.
    $clusters = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // The respond function will handle the JSON header and echo the results.
    respond([
        'success' => true, 
        'clusters' => $clusters
    ]);

} catch (PDOException $e) {
    // We will log the actual error message to the server logs for your debugging.
    error_log("Database Error in list.php: " . $e->getMessage());
    
    // We will return a generic message to the user for security.
    respond(['success' => false, 'message' => 'A database error occurred.'], 500);
}