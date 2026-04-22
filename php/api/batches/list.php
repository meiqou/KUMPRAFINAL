<?php
// kumpra/api/batches/list.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/maps.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$userId = validateToken();
$clusterId = (int)($_GET['cluster_id'] ?? 0);

if ($clusterId <= 0) {
    respond(['success' => false, 'message' => 'cluster_id is required']);
}

define('DEFAULT_EST_TRAVEL_TIME', 5700); // 95 minutes in seconds

$db = getDB();

$stmt = $db->prepare('
    SELECT 
        b.batch_id,
        b.status,
        b.current_count,
        b.size_limit,
        b.threshold_reached_at,
        b.timer_expiry,
        b.load_capacity_kg,
        b.total_weight,
        b.created_at,
        c.latitude,
        c.longitude,
        c.barangay_name,
        c.street_zone,
        CASE WHEN o.order_id IS NOT NULL THEN 1 ELSE 0 END AS user_joined
    FROM batches b
    JOIN clusters c ON b.cluster_id = c.cluster_id
    LEFT JOIN orders o ON o.batch_id = b.batch_id AND o.user_id = ?
    WHERE b.cluster_id = ?
      AND DATE(b.created_at) = CURDATE()
      AND b.status NOT IN ("Completed", "Cancelled")
    ORDER BY b.created_at ASC
');
$stmt->execute([$userId, $clusterId]);
$rows = $stmt->fetchAll();

// Format for the app
$batches = array_map(function($row) {
    $departure = date('h:i A', strtotime($row['created_at']));
    
    // Ensure coordinates are valid; fallback to Bacolod City Center if 0 or NULL
    $lat = (!empty($row['latitude']) && (float)$row['latitude'] != 0) 
        ? (float)$row['latitude'] 
        : 10.6765;
    $lng = (!empty($row['longitude']) && (float)$row['longitude'] != 0) 
        ? (float)$row['longitude'] 
        : 122.9513;

    $arrival = date('h:i A', strtotime($row['created_at']) + DEFAULT_EST_TRAVEL_TIME);
    $fee = $row['current_count'] > 0
        ? round(300 / max($row['current_count'], 1), 2)
        : 300.0;

    $statusMap = [
        'Gathering'  => 'Open',
        'Last_Call'  => 'Last Call',
        'Locked'     => 'Departing Soon',
        'Purchasing' => 'At Market',
        'In_Transit' => 'On the Way',
    ];

    return [
        'batch_id'    => (int)$row['batch_id'],
        'name'        => strtoupper($row['barangay_name']) . '-' . $row['batch_id'],
        'address'     => $row['street_zone'],
        'cluster_name' => $row['barangay_name'],
        'status'      => $statusMap[$row['status']] ?? $row['status'],
        'departure'   => $departure,
        'est_arrival' => $arrival,
        'joined'      => (int)$row['current_count'],
        'size_limit'  => (int)$row['size_limit'],
        'shared_fee'  => $fee,
        'is_active'   => in_array($row['status'], ['Gathering', 'Last_Call']),
        'user_joined' => (bool)$row['user_joined'],
        'rider_name'  => $row['rider_name'],
        'map_config'  => [
            'api_key'         => GEOAPIFY_API_KEY,
            'static_map_url'  => "https://maps.geoapify.com/v1/staticmap?style=osm-bright&width=1200&height=800&center=lonlat:$lng,$lat&zoom=15&marker=lonlat:$lng,$lat;type:awesome;color:%23ef4444&apiKey=" . GEOAPIFY_API_KEY,
            'apple_maps_url'  => "https://maps.apple.com/?q=$lat,$lng",
            'native_geo_url'  => "geo:$lat,$lng?q=$lat,$lng",
            'interactive_url' => "https://maps.geoapify.com/v1/staticmap?style=osm-bright&width=1200&height=800&center=lonlat:$lng,$lat&zoom=15&marker=lonlat:$lng,$lat;type:awesome;color:%23ef4444&apiKey=" . GEOAPIFY_API_KEY,
            'routing_url'     => "https://api.geoapify.com/v1/routing?waypoints=" . MARKET_LAT . "," . MARKET_LNG . "|$lat,$lng&mode=drive&apiKey=" . GEOAPIFY_API_KEY,
            'market_coords'   => ['lat' => MARKET_LAT, 'lng' => MARKET_LNG]
        ]
    ];
}, $rows);

respond(['success' => true, 'batches' => $batches]);
