<?php
// Prevent any accidental output before headers
ob_start();

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");

/**
 * Standardized form-encoded response helper
 */
function respond(array $data, int $status = 200): void {
    // Clear buffer to ensure only the encoded payload is sent
    if (ob_get_length()) ob_clean();

    $data = normalizeResponseValue($data);
    
    http_response_code($status);
    header('Content-Type: application/x-www-form-urlencoded; charset=utf-8');
    echo http_build_query($data, '', '&', PHP_QUERY_RFC3986);
    exit;
}

function normalizeResponseValue($value) {
    if (is_array($value)) {
        $normalized = [];
        foreach ($value as $key => $item) {
            $normalized[$key] = normalizeResponseValue($item);
        }
        return $normalized;
    }

    if (is_bool($value)) {
        return $value ? 'true' : 'false';
    }

    return $value;
}

// Handle Preflight OPTIONS request immediately
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}