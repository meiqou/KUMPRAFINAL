<?php
// kumpra/api/config/database.php

define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
define('DB_NAME', getenv('DB_NAME') ?: 'u793073111_kumpra');
define('DB_USER', getenv('DB_USER') ?: 'u793073111_kumpra');
define('DB_PASS', getenv('DB_PASS') ?: 'Kumpra123');
define('JWT_SECRET', getenv('JWT_SECRET') ?: 'kumpra_secret_key_change_this_in_production');

function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $hosts = array_values(array_unique(array_filter([
            DB_HOST,
            DB_HOST === 'localhost' ? '127.0.0.1' : null,
            getenv('DB_HOST_ALT') ?: null,
        ])));

        $lastException = null;
        foreach ($hosts as $host) {
            try {
                $pdo = new PDO(
                    "mysql:host={$host};dbname=" . DB_NAME . ";charset=utf8mb4",
                    DB_USER,
                    DB_PASS,
                    [
                        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                        PDO::ATTR_EMULATE_PREPARES   => false,
                    ]
                );
                break;
            } catch (PDOException $e) {
                $lastException = $e;
                error_log('Database connection failed for host ' . $host . ': ' . $e->getMessage());
            }
        }

        if ($pdo === null) {
            http_response_code(500);
            die('success=false&message=' . rawurlencode('Database connection failed. Please check the server configuration.'));
        }
    }
    return $pdo;
}

function getUsersIdColumn(PDO $db): string {
    static $columnName = null;
    if ($columnName !== null) {
        return $columnName;
    }

    $stmt = $db->prepare('
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = "users"
          AND COLUMN_NAME IN ("user_id", "id")
        ORDER BY FIELD(COLUMN_NAME, "user_id", "id")
        LIMIT 1
    ');
    $stmt->execute();
    $columnName = $stmt->fetchColumn();

    if (!$columnName) {
        $columnName = 'user_id';
    }

    return $columnName;
}

function hasTableColumn(PDO $db, string $tableName, string $columnName): bool {
    static $cache = [];
    $cacheKey = $tableName . '.' . $columnName;
    if (array_key_exists($cacheKey, $cache)) {
        return $cache[$cacheKey];
    }

    $stmt = $db->prepare('
        SELECT 1
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = ?
          AND COLUMN_NAME = ?
        LIMIT 1
    ');
    $stmt->execute([$tableName, $columnName]);
    $cache[$cacheKey] = (bool)$stmt->fetchColumn();

    return $cache[$cacheKey];
}

function getRidersIdColumn(PDO $db): string {
    static $columnName = null;
    if ($columnName !== null) {
        return $columnName;
    }

    $stmt = $db->prepare('
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = "riders"
          AND COLUMN_NAME IN ("rider_id", "id")
        ORDER BY FIELD(COLUMN_NAME, "rider_id", "id")
        LIMIT 1
    ');
    $stmt->execute();
    $columnName = $stmt->fetchColumn();

    if (!$columnName) {
        $columnName = \'rider_id\';
    }

    return $columnName;
}

function getRidersPasswordColumn(PDO $db): string {
    static $columnName = null;
    if ($columnName !== null) {
        return $columnName;
    }

    if (hasTableColumn($db, \'riders\', \'password\')) {
        $columnName = \'password\';
        return $columnName;
    }

    if (hasTableColumn($db, \'riders\', \'password_hash\')) {
        $columnName = \'password_hash\';
        return $columnName;
    }

    try {
        $db->exec("ALTER TABLE riders ADD COLUMN password VARCHAR(255) NOT NULL DEFAULT \'\' AFTER work_shift");
        $columnName = \'password\';
    } catch (PDOException $e) {
        error_log(\'Unable to add password column to riders table: \' . $e->getMessage());
        $columnName = \'password\';
    }

    return $columnName;
}

function getUsersPasswordColumn(PDO $db): string {
    static $columnName = null;
    if ($columnName !== null) {
        return $columnName;
    }

    if (hasTableColumn($db, \'users\', \'password\')) {
        $columnName = \'password\';
        return $columnName;
    }

    if (hasTableColumn($db, \'users\', \'password_hash\')) {
        $columnName = \'password_hash\';
        return $columnName;
    }

    try {
        $db->exec("ALTER TABLE users ADD COLUMN password VARCHAR(255) NOT NULL DEFAULT \'\' AFTER username");
        $columnName = \'password\';
    } catch (PDOException $e) {
        error_log(\'Unable to add password column to users table: \' . $e->getMessage());
        $columnName = \'password\';
    }

    return $columnName;
}

// FIX: Removed the duplicate respond() definition that was here previously.
//      respond() is already defined in cors.php, which is always require_once'd first.
//      Having two definitions caused a PHP Fatal Error: "Cannot redeclare respond()".

function getRequestBody(): array {
    $raw = file_get_contents('php://input');
    $decoded = json_decode($raw, true);
    if (is_array($decoded)) {
        return $decoded;
    }

    return $_POST ?? [];
}

// Simple JWT implementation
function generateToken(int $userId, string $type = 'user'): string {
    $header    = base64_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $payload   = base64_encode(json_encode([
        'user_id' => $userId,
        'type' => $type,
        'exp'     => time() + (30 * 24 * 60 * 60), // 30 days
    ]));
    $signature = base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    return "$header.$payload.$signature";
}

function validateToken(string $type = null): int {
    $headers = getallheaders();
    $auth    = $headers['Authorization'] ?? '';
    $token = '';
    if (isset($auth) && strpos($auth, 'Bearer ') === 0) {
        $token = substr($auth, 7);
    } else {
        $body = getRequestBody();
        $token = trim((string)($body['token'] ?? ($_GET['token'] ?? '')));
    }

    if ($token === '') {
        respond(['success' => false, 'message' => 'Unauthorized'], 401);
    }

    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        respond(['success' => false, 'message' => 'Invalid token'], 401);
    }
    [$header, $payload, $sig] = $parts;
    $expectedSig = base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    if ($sig !== $expectedSig) {
        respond(['success' => false, 'message' => 'Invalid token'], 401);
    }
    $data = json_decode(base64_decode($payload), true);
    if ($data['exp'] < time()) {
        respond(['success' => false, 'message' => 'Token expired'], 401);
    }
    if ($type && ($data['type'] ?? '') !== $type) {
        respond(['success' => false, 'message' => 'Invalid token type'], 401);
    }
    return (int) $data['user_id'];
}
