<?php
// kumpra/api/auth/rider_register.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(['success' => false, 'message' => 'Invalid request method'], 405);
}

$data = getRequestBody();
$name = trim($data['name'] ?? '');
$plateNumber = trim($data['plate_number'] ?? '');
$phone = trim($data['phone'] ?? '');
$workShift = trim($data['work_shift'] ?? '');
$password = $data['password'] ?? '';

// Input validation
if (empty($name) || empty($plateNumber) || empty($phone) || strlen($password) < 6) {
    respond(['success' => false, 'message' => 'All fields required, password 6+ chars'], 400);
}
if (!preg_match('/^09\d{9}$/', $phone)) {
    respond(['success' => false, 'message' => 'Phone must be 09xxxxxxxxx format'], 400);
}
if (!in_array($workShift, ['Morning', 'Afternoon', 'Evening'])) {
    respond(['success' => false, 'message' => 'Work shift must be Morning/Afternoon/Evening'], 400);
}

try {
    $pdo = getDB();

    // Check duplicates
    $stmt = $pdo->prepare('SELECT 1 FROM riders WHERE plate_number = ? OR phone = ?');
    $stmt->execute([$plateNumber, $phone]);
    if ($stmt->fetch()) {
        respond(['success' => false, 'message' => 'Plate or phone already registered'], 409);
    }

    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    $username = strtolower(str_replace(' ', '_', $name)) . '_' . substr(md5(time()), 0, 4);
    $accountNumber = 'RIDER-' . str_pad(time() % 100000, 5, '0', STR_PAD_LEFT);

    $stmt = $pdo->prepare('INSERT INTO riders (name, plate_number, phone, work_shift, password, status, username, account_number, created_at) VALUES (?, ?, ?, ?, ?, "active", ?, ?, NOW())');
    $stmt->execute([$name, $plateNumber, $phone, $workShift, $hashedPassword, $username, $accountNumber]);

    $riderId = $pdo->lastInsertId();

    $stmt = $pdo->prepare('SELECT rider_id, name, plate_number, phone, work_shift, status, username, account_number FROM riders WHERE rider_id = ?');
    $stmt->execute([$riderId]);
    $rider = $stmt->fetch(PDO::FETCH_ASSOC);

    $rider['token'] = generateToken($riderId, 'rider');

    respond(['success' => true, 'message' => 'Rider registered!', 'rider' => $rider]);

} catch (Exception $e) {
    error_log('Rider register error: ' . $e->getMessage());
    respond(['success' => false, 'message' => 'Registration failed'], 500);
}
?>

