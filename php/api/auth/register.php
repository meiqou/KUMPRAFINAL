<?php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(['success' => false, 'message' => 'Invalid request method'], 405);
}

$data = getRequestBody();
$fullName = trim($data['name'] ?? '');
$username = trim($data['username'] ?? '');
$email = trim($data['email'] ?? '');
$phone = trim($data['phone'] ?? '');
$password = (string)($data['password'] ?? '');
$clusterId = filter_var($data['cluster_id'] ?? '', FILTER_VALIDATE_INT);

if ($fullName === '') {
    respond(['success' => false, 'message' => 'Name is required.'], 400);
}
if ($username === '') {
    respond(['success' => false, 'message' => 'Username is required.'], 400);
}
if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    respond(['success' => false, 'message' => 'A valid email address is required.'], 400);
}
if (empty($phone) || !preg_match('/^09\d{9}$/', $phone)) {
    respond(['success' => false, 'message' => 'A valid 11-digit mobile number is required (e.g., 09xxxxxxxxx).'], 400);
}
if (strlen($password) < 6) {
    respond(['success' => false, 'message' => 'Password must be at least 6 characters.'], 400);
}
if ($clusterId === false || $clusterId <= 0) {
    respond(['success' => false, 'message' => 'A valid cluster must be selected.'], 400);
}

try {
    $pdo = getDB();
    $userIdColumn = getUsersIdColumn($pdo);
    $passwordColumn = getUsersPasswordColumn($pdo);

    $clusterStmt = $pdo->prepare('SELECT 1 FROM clusters WHERE cluster_id = ?');
    $clusterStmt->execute([$clusterId]);
    if (!$clusterStmt->fetch()) {
        respond(['success' => false, 'message' => 'The selected cluster does not exist. Please choose a valid barangay.'], 400);
    }

    $usernameStmt = $pdo->prepare('SELECT 1 FROM users WHERE username = ?');
    $usernameStmt->execute([$username]);
    if ($usernameStmt->fetch()) {
        respond(['success' => false, 'message' => 'This username is already taken.'], 409);
    }

    if (hasTableColumn($pdo, 'users', 'email')) {
        $emailStmt = $pdo->prepare('SELECT 1 FROM users WHERE email = ?');
        $emailStmt->execute([$email]);
        if ($emailStmt->fetch()) {
            respond(['success' => false, 'message' => 'This email is already registered.'], 409);
        }
    }

    if (hasTableColumn($pdo, 'users', 'mobile_number')) {
        $phoneStmt = $pdo->prepare('SELECT 1 FROM users WHERE mobile_number = ?');
        $phoneStmt->execute([$phone]);
        if ($phoneStmt->fetch()) {
            respond(['success' => false, 'message' => 'This mobile number is already registered.'], 409);
        }
    }

    $userColumns = ['full_name', 'username', $passwordColumn, 'cluster_id'];
    $userValues = [$fullName, $username, password_hash($password, PASSWORD_DEFAULT), $clusterId];

    if (hasTableColumn($pdo, 'users', 'email')) {
        $userColumns[] = 'email';
        $userValues[] = $email;
    }

    if (hasTableColumn($pdo, 'users', 'mobile_number')) {
        $userColumns[] = 'mobile_number';
        $userValues[] = $phone;
    }
    if (hasTableColumn($pdo, 'users', 'preferences')) {
        $userColumns[] = 'preferences';
        $userValues[] = null;
    }
    if (hasTableColumn($pdo, 'users', 'special_instructions')) {
        $userColumns[] = 'special_instructions';
        $userValues[] = null;
    }
    if (hasTableColumn($pdo, 'users', 'role')) {
        $userColumns[] = 'role';
        $userValues[] = 'user';
    }
    if (hasTableColumn($pdo, 'users', 'is_verified')) {
        $userColumns[] = 'is_verified';
        $userValues[] = 0;
    }
    if (hasTableColumn($pdo, 'users', 'created_at')) {
        $userColumns[] = 'created_at';
        $userValues[] = date('Y-m-d H:i:s');
    }

    $placeholders = implode(', ', array_fill(0, count($userColumns), '?'));
    $sql = 'INSERT INTO users (' . implode(', ', $userColumns) . ') VALUES (' . $placeholders . ')';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($userValues);

    $newUserId = $pdo->lastInsertId();
    $stmt = $pdo->prepare('
        SELECT
            u.' . $userIdColumn . ' AS user_id,
            u.full_name AS name,
            u.username,
            u.email,
            u.mobile_number AS phone_number,
            u.cluster_id,
            c.barangay_name AS cluster_name
        FROM users u
        JOIN clusters c ON u.cluster_id = c.cluster_id
        WHERE u.' . $userIdColumn . ' = ?
        LIMIT 1
    ');
    $stmt->execute([$newUserId]);
    $user = $stmt->fetch();

    if (!$user) {
        respond(['success' => false, 'message' => 'Registration completed but the user record could not be loaded.'], 500);
    }

    $user['token'] = generateToken((int)$user['user_id']);

    respond(['success' => true, 'user' => $user]);
} catch (PDOException $e) {
    error_log('Database error in register.php: ' . $e->getMessage());
    respond(['success' => false, 'message' => 'Database error: ' . $e->getMessage()], 500);
}