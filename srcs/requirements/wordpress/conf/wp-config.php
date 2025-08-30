<?php

// Database settings from environment
define('DB_NAME',     getenv('MYSQL_DB')       ?: 'wordpress');
define('DB_USER',     getenv('MYSQL_USER')     ?: 'wpuser');
define('DB_PASSWORD', getenv('MYSQL_PASSWORD') ?: 'wppass');
define('DB_HOST',     'mariadb:3306');
define('DB_CHARSET',  'utf8');
define('DB_COLLATE',  '');

// Table prefix
$table_prefix = 'wp_';

// Redis settings
define('WP_REDIS_HOST', getenv('WP_REDIS_HOST') ?: 'redis');
define('WP_REDIS_PORT', (int)(getenv('WP_REDIS_PORT') ?: 6379));
define('WP_REDIS_DATABASE', (int)(getenv('REDIS_DATABASE') ?: 0));
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_SCHEME', 'tcp');
define('WP_REDIS_PREFIX', 'wp_' . (getenv('MYSQL_DB') ?: 'wordpress') . '_');

// Authentication Unique Keys and Salts.
define('AUTH_KEY',         getenv('AUTH_KEY')         ?: 'change-me-auth-key');
define('SECURE_AUTH_KEY',  getenv('SECURE_AUTH_KEY')  ?: 'change-me-secure-auth-key');
define('LOGGED_IN_KEY',    getenv('LOGGED_IN_KEY')    ?: 'change-me-logged-in-key');
define('NONCE_KEY',        getenv('NONCE_KEY')        ?: 'change-me-nonce-key');
define('AUTH_SALT',        getenv('AUTH_SALT')        ?: 'change-me-auth-salt');
define('SECURE_AUTH_SALT', getenv('SECURE_AUTH_SALT') ?: 'change-me-secure-auth-salt');
define('LOGGED_IN_SALT',   getenv('LOGGED_IN_SALT')   ?: 'change-me-logged-in-salt');
define('NONCE_SALT',       getenv('NONCE_SALT')       ?: 'change-me-nonce-salt');

// Absolute path to the WordPress directory.
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

// Include the WordPress settings.
require_once ABSPATH . 'wp-settings.php';
