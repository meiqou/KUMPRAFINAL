<?php
// kumpra/api/auth/rider_login.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$data = getRequestBody();
$identifier = trim($data['identifier'] ?? '');
$password = $data['password'] ?? '';

if (empty($identifier) || empty($password)) {
    respond(['success' => false, 'message' => 'Identifier and password required'], 400);
}

try {
    $db = getDB();

    $stmt = $db->prepare('
        SELECT rider_id, name, plate_number, phone, work_shift, status, password, account_number, username 
        FROM riders 
        WHERE plate_number = ? OR phone = ? OR account_number = ? OR username = ?
    ');
    $stmt->execute([$identifier, $identifier, $identifier, $identifier]);
    $rider = $stmt->fetch();

    if (!$rider || $rider['status'] !== 'active') {
        respond(['success' => false, 'message' => 'Invalid credentials'], 401);
    }

    if (!password_verify($password, $rider['password'])) {
        respond(['success' => false, 'message' => 'Invalid credentials'], 401);
    }

    $rider['token'] = generateToken((int)$rider['rider_id'], 'rider');
    unset($rider['password']);

    respond(['success' => true, 'message' => 'Login successful', 'rider' => $rider]);

} catch (Exception $e) {
    error_log('Rider login error: ' . $e->getMessage());
    respond(['success' => false, 'message' => 'Login failed'], 500);
}
?>

