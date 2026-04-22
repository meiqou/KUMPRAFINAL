<?php
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error_log('update.php: Invalid method ' . $_SERVER['REQUEST_METHOD']);
    respond(['success' => false, 'message' => 'Invalid request method'], 405);
}

error_log('update.php: Request from ' . $_SERVER['REMOTE_ADDR'] . ', User-Agent: ' . ($_SERVER['HTTP_USER_AGENT'] ?? 'unknown'));

try {
    $pdo = getDB();
$userId = validateToken();
error_log("update.php: Valid token for user_id=$userId");
    $userIdColumn = getUsersIdColumn($pdo);

    $data = getRequestBody();
    $fullName = trim($data['name'] ?? '');
    $username = trim($data['username'] ?? '');
    $email = trim($data['email'] ?? '');
    $phone = trim($data['phone'] ?? '');
    $password = trim($data['password'] ?? '');
    $clusterIdRaw = $data['cluster_id'] ?? '';
    $clusterId = $clusterIdRaw !== '' ? filter_var($clusterIdRaw, FILTER_VALIDATE_INT) : null;

    $hasEmail = hasTableColumn($pdo, 'users', 'email');
    $hasPhone = hasTableColumn($pdo, 'users', 'mobile_number');

    if ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        respond(['success' => false, 'message' => 'A valid email address is required.'], 400);
    }

    if ($password !== '' && strlen($password) < 6) {
        respond(['success' => false, 'message' => 'Password must be at least 6 characters.'], 400);
    }

    if ($phone !== '' && !preg_match('/^09\d{9}$/', $phone)) {
        respond(['success' => false, 'message' => 'A valid 11-digit mobile number is required.'], 400);
    }

    if ($clusterIdRaw !== '' && ($clusterId === false || $clusterId <= 0)) {
        respond(['success' => false, 'message' => 'A valid cluster must be selected.'], 400);
    }

    $stmt = $pdo->prepare('SELECT ' . $userIdColumn . ' AS user_id, username' . ($hasEmail ? ', email' : '') . ($hasPhone ? ', mobile_number' : '') . ', cluster_id FROM users WHERE ' . $userIdColumn . ' = ? LIMIT 1');
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    if (!$user) {
        respond(['success' => false, 'message' => 'User not found.'], 404);
    }

    if ($username !== '' && $username !== $user['username']) {
        $stmt = $pdo->prepare('SELECT 1 FROM users WHERE username = ? AND ' . $userIdColumn . ' != ?');
        $stmt->execute([$username, $userId]);
        if ($stmt->fetch()) {
            respond(['success' => false, 'message' => 'This username is already taken.'], 409);
        }
    }

    if ($email !== '' && $hasEmail && $email !== ($user['email'] ?? '')) {
        $stmt = $pdo->prepare('SELECT 1 FROM users WHERE email = ? AND ' . $userIdColumn . ' != ?');
        $stmt->execute([$email, $userId]);
        if ($stmt->fetch()) {
            respond(['success' => false, 'message' => 'This email is already registered.'], 409);
        }
    }

    if ($phone !== '' && $hasPhone && $phone !== ($user['mobile_number'] ?? '')) {
        $stmt = $pdo->prepare('SELECT 1 FROM users WHERE mobile_number = ? AND ' . $userIdColumn . ' != ?');
        $stmt->execute([$phone, $userId]);
        if ($stmt->fetch()) {
            respond(['success' => false, 'message' => 'This mobile number is already registered.'], 409);
        }
    }

    if ($clusterId !== null && $clusterId !== (int)$user['cluster_id']) {
        $clusterStmt = $pdo->prepare('SELECT 1 FROM clusters WHERE cluster_id = ?');
        $clusterStmt->execute([$clusterId]);
        if (!$clusterStmt->fetch()) {
            respond(['success' => false, 'message' => 'The selected cluster does not exist. Please choose a valid barangay.'], 400);
        }
    }

    $updates = [];
    $params = [];

    if ($fullName !== '') {
        $updates[] = 'full_name = ?';
        $params[] = $fullName;
    }
    if ($username !== '') {
        $updates[] = 'username = ?';
        $params[] = $username;
    }
    if ($email !== '' && $hasEmail) {
        $updates[] = 'email = ?';
        $params[] = $email;
    }
    if ($phone !== '' && $hasPhone) {
        $updates[] = 'mobile_number = ?';
        $params[] = $phone;
    }
    if ($clusterId !== null) {
        $updates[] = 'cluster_id = ?';
        $params[] = $clusterId;
    }
    if ($password !== '') {
        $passwordColumn = getUsersPasswordColumn($pdo);
        $updates[] = $passwordColumn . ' = ?';
        $params[] = password_hash($password, PASSWORD_DEFAULT);
    }

    if (!empty($updates)) {
        $sql = 'UPDATE users SET ' . implode(', ', $updates) . ' WHERE ' . $userIdColumn . ' = ?';
        $params[] = $userId;
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
    }

    $selectCols = [
        "u.$userIdColumn AS user_id",
        "u.full_name AS name",
        "u.username",
        "u.cluster_id",
        "c.barangay_name AS cluster_name"
    ];
    if ($hasEmail) $selectCols[] = "u.email";
    if ($hasPhone) $selectCols[] = "u.mobile_number AS phone_number";

    $sql = "SELECT " . implode(', ', $selectCols) . " FROM users u LEFT JOIN clusters c ON u.cluster_id = c.cluster_id WHERE u.$userIdColumn = ? LIMIT 1";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$userId]);
    $updatedUser = $stmt->fetch();

    if (!$updatedUser) {
        respond(['success' => false, 'message' => 'Unable to load updated profile.'], 500);
    }

    respond(['success' => true, 'user' => $updatedUser]);
} catch (PDOException $e) {
    error_log('Database error in update.php: ' . $e->getMessage());
    respond(['success' => false, 'message' => 'Database error: ' . $e->getMessage()], 500);
}
