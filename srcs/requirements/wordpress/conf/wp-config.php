<?php

// Database settings from environment
define('DB_NAME',     getenv('MYSQL_DB'));
define('DB_USER',     getenv('MYSQL_USER'));
define('DB_PASSWORD', getenv('MYSQL_PASSWORD'));
define('DB_HOST',     'mariadb:3306');
define('DB_CHARSET',  'utf8mb4');
define('DB_COLLATE',  'utf8mb4_unicode_ci');

// Validate required environment variables
if (!DB_NAME || !DB_USER || !DB_PASSWORD) {
    error_log('FATAL: Missing required database environment variables');
    die('Database configuration error. Check environment variables.');
}

// Table prefix
$table_prefix = 'wp_';

// Redis settings (only define if Redis service is available)
define('WP_REDIS_HOST', getenv('REDIS_HOST'));
define('WP_REDIS_PORT', (int)(getenv('REDIS_PORT')));
define('WP_REDIS_DATABASE', (int)(getenv('REDIS_DATABASE')));
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_SCHEME', 'tcp');
define('WP_REDIS_PREFIX', 'wp_' . (getenv('MYSQL_DB') ?: 'wordpress') . '_');

// Authentication Unique Keys and Salts
define('AUTH_KEY',         getenv('AUTH_KEY')         ?: 'put your unique phrase here');
define('SECURE_AUTH_KEY',  getenv('SECURE_AUTH_KEY')  ?: 'put your unique phrase here');
define('LOGGED_IN_KEY',    getenv('LOGGED_IN_KEY')    ?: 'put your unique phrase here');
define('NONCE_KEY',        getenv('NONCE_KEY')        ?: 'put your unique phrase here');
define('AUTH_SALT',        getenv('AUTH_SALT')        ?: 'put your unique phrase here');
define('SECURE_AUTH_SALT', getenv('SECURE_AUTH_SALT') ?: 'put your unique phrase here');
define('LOGGED_IN_SALT',   getenv('LOGGED_IN_SALT')   ?: 'put your unique phrase here');
define('NONCE_SALT',       getenv('NONCE_SALT')       ?: 'put your unique phrase here');

// WordPress security settings
define('DISALLOW_FILE_EDIT', true);
define('WP_POST_REVISIONS', 3);

// Memory limit
ini_set('memory_limit', '512M');

// Absolute path to the WordPress directory
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

// Include the WordPress settings
require_once ABSPATH . 'wp-settings.php';
