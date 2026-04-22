<?php
// kumpra/api/auth/login.php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(['success' => false, 'message' => 'Method not allowed'], 405);
}

$body = getRequestBody();
$identifier = trim($body['identifier'] ?? '');
$password = (string)($body['password'] ?? '');

if (empty($identifier)) respond(['success' => false, 'message' => 'Username, phone number, or email is required']);
if ($password === '') respond(['success' => false, 'message' => 'Password is required']);

$db = getDB();
$userIdColumn = getUsersIdColumn($db);
$passwordColumn = getUsersPasswordColumn($db);

$lookupColumns = ['username'];
if (hasTableColumn($db, 'users', 'mobile_number')) {
    $lookupColumns[] = 'mobile_number';
}
if (hasTableColumn($db, 'users', 'email')) {
    $lookupColumns[] = 'email';
}

$conditions = [];
foreach ($lookupColumns as $column) {
    $conditions[] = 'u.' . $column . ' = ?';
}

$stmt = $db->prepare('
    SELECT u.' . $userIdColumn . ' AS user_id, u.full_name AS name, u.username, u.' . $passwordColumn . ' AS password_value, u.cluster_id, c.barangay_name
    FROM users u
    JOIN clusters c ON u.cluster_id = c.cluster_id
    WHERE ' . implode(' OR ', $conditions) . '
    LIMIT 1
');
$stmt->execute(array_fill(0, count($lookupColumns), $identifier));
$user = $stmt->fetch();

if (!$user) {
    respond(['success' => false, 'message' => 'No account found with that login identifier. Please sign up.']);
}

$storedPassword = (string)($user['password_value'] ?? '');
if ($storedPassword === '' || !password_verify($password, $storedPassword)) {
    respond(['success' => false, 'message' => 'Invalid username or password.']);
}

$token = generateToken((int)$user['user_id']);

respond([
    'success' => true,
    'message' => 'Login successful',
    'user' => [
        'user_id' => $user['user_id'],
        'name' => $user['name'],
        'username' => $user['username'],
        'cluster_id' => $user['cluster_id'],
        'cluster_name' => $user['barangay_name'],
        'token' => $token,
    ],
]);
