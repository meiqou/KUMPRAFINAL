<?php
// Simple PHP test
header('Content-Type: text/plain');
echo "PHP is working!\n";
echo "Current directory: " . __DIR__ . "\n";
echo "Config file exists: " . (file_exists('../config/database.php') ? 'YES' : 'NO') . "\n";
echo "CORS file exists: " . (file_exists('../config/cors.php') ? 'YES' : 'NO') . "\n";
echo "Config dir exists: " . (is_dir('../config') ? 'YES' : 'NO') . "\n";
echo "Parent directory contents:\n";
$parent = dirname(__DIR__);
$files = scandir($parent);
foreach ($files as $file) {
    if ($file !== '.' && $file !== '..') {
        echo "  - $file" . (is_dir("$parent/$file") ? '/' : '') . "\n";
    }
}
echo "\nConfig directory contents (if exists):\n";
if (is_dir('../config')) {
    $configFiles = scandir('../config');
    foreach ($configFiles as $file) {
        if ($file !== '.' && $file !== '..') {
            echo "  - $file" . (is_dir("../config/$file") ? '/' : '') . "\n";
        }
    }
} else {
    echo "  Config directory does not exist!\n";
}

