<?php
// kumpra/api/auth/register.php
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
$password = (string)($data['password'] ?? '');

// Input validation
if (empty($name)) {
    respond(['success' => false, 'message' => 'Name is required.'], 400);
}
if (empty($plateNumber)) {
    respond(['success' => false, 'message' => 'Plate number is required.'], 400);
}
if (empty($phone) || !preg_match('/^09\d{9}$/', $phone)) {
    respond(['success' => false, 'message' => 'A valid 11-digit mobile number is required (e.g., 09xxxxxxxxx).'], 400);
}
if (strlen($password) < 6) {
    respond(['success' => false, 'message' => 'Password must be at least 6 characters.'], 400);
}

// Validate work_shift against allowed values
$allowedWorkShifts = ['Morning', 'Afternoon', 'Evening'];
if (!in_array($workShift, $allowedWorkShifts)) {
    respond(['success' => false, 'message' => 'Invalid work shift provided. Must be Morning, Afternoon, or Evening.'], 400);
}

try {
    $pdo = getDB();
    $riderIdColumn = 'rider_id';
    $passwordColumn = 'password';

    // Check if plate number already exists
    $plateStmt = $pdo->prepare('SELECT 1 FROM riders WHERE plate_number = ?');
    $plateStmt->execute([$plateNumber]);
    if ($plateStmt->fetch()) {
        respond(['success' => false, 'message' => 'This plate number is already registered.'], 409);
    }

    // Check if phone number already exists
    $phoneStmt = $pdo->prepare('SELECT 1 FROM riders WHERE phone = ?');
    $phoneStmt->execute([$phone]);
    if ($phoneStmt->fetch()) {
        respond(['success' => false, 'message' => 'This phone number is already registered.'], 409);
    }

    // Hash the password
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    // Prepare and execute the insert statement
    $columns = ['name', 'plate_number', 'phone', 'work_shift', 'password', 'status', 'created_at', 'username', 'account_number'];
    $values = [$name, $plateNumber, $phone, $workShift, $hashedPassword, 'active', date('Y-m-d H:i:s'), strtolower(str_replace(' ', '_', $name)) . '_' . substr(md5(microtime()), 0, 4), 'RIDER-' . time()]; 

    $placeholders = implode(', ', array_fill(0, count($columns), '?'));
    $sql = 'INSERT INTO riders (' . implode(', ', $columns) . ') VALUES (' . $placeholders . ')';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($values);

    $newRiderId = $pdo->lastInsertId();

    // Fetch the newly registered rider's data
    $stmt = $pdo->prepare('
        SELECT
            r.rider_id,
            r.name,
            r.plate_number,
            r.phone,
            r.work_shift,
            r.status,
            r.account_number,
            r.username
        FROM riders r
        WHERE r.rider_id = ?
        LIMIT 1
    ');
    $stmt->execute([$newRiderId]);
    $rider = $stmt->fetch(PDO::FETCH_ASSOC); 

    if (!$rider) {
        respond(['success' => false, 'message' => 'Registration completed but rider data could not be retrieved.'], 500);
    }

    // Generate a token for the new rider
    $rider['token'] = generateToken((int)$rider['rider_id']);

    respond(['success' => true, 'message' => 'Rider registered successfully!', 'rider' => $rider]);

} catch (PDOException $e) {
    // Log the actual database error for debugging
    error_log('Database error in riders/auth/register.php: ' . $e->getMessage());
    respond(['success' => false, 'message' => 'Database error during registration. Please try again later.'], 500);
} catch (Exception $e) {
    // Catch any other unexpected errors
    error_log('General error in riders/auth/register.php: ' . $e->getMessage());
    respond(['success' => false, 'message' => 'An unexpected error occurred during registration.'], 500);
}
?>