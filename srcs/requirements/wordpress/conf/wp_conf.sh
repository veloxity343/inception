#!/bin/bash
set -e

echo "Starting WordPress configuration..."

#=== Debug Shell Setup ===
setup_debug_shell() {
    if [ "${DEBUG_MODE:-false}" = "true" ]; then
        echo "DEBUG_MODE enabled - setting up zsh..."
        chsh -s $(which zsh) 2>/dev/null || true
        wget -q https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O /tmp/install.sh 2>/dev/null || true
        if [ -f /tmp/install.sh ]; then
            sed -i '553i echo alias wp=\\"wp --allow-root --path=/var/www/wordpress\\" >> ~/.zshrc' /tmp/install.sh
            sh /tmp/install.sh --unattended 2>/dev/null || true
            echo "alias zshi='sh /tmp/install.sh'" >> ~/.zshrc
        fi
        echo "Zsh setup complete"
    fi
}

#=== Database Connection Check ===
wait_for_database() {
    echo "Waiting for MariaDB to be ready..."
    
    local start_time=$(date +%s)
    local timeout=30
    local end_time=$((start_time + timeout))
    
    while [ $(date +%s) -lt $end_time ]; do
        if nc -zv mariadb 3306 >/dev/null 2>&1; then
            echo "✅ MariaDB is up and running!"
            return 0
        else
            echo "⏳ Waiting for MariaDB to start..."
            sleep 2
        fi
    done
    
    echo "❌ MariaDB connection timeout after ${timeout}s"
    exit 1
}

#=== WordPress Installation ===
setup_wordpress() {
    echo "Setting up WordPress..."
    
    # Create WordPress directory with proper permissions
    mkdir -p /var/www/wordpress
    chmod -R 755 /var/www/wordpress/
    chown -R www-data:www-data /var/www/wordpress
    
    # Navigate to WordPress directory
    cd /var/www/wordpress
    
    # Download and install WP-CLI
    if [ ! -f /usr/local/bin/wp ]; then
        echo "Installing WP-CLI..."
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
        echo "WP-CLI installed successfully"
    fi
    
    # Check if WordPress is already installed
    if wp core is-installed --allow-root >/dev/null 2>&1; then
        echo "✅ WordPress already installed, skipping setup"
        return 0
    fi
    
    echo "🚀 Installing WordPress..."
    
    # Clean directory and download WordPress
    find /var/www/wordpress/ -mindepth 1 -delete 2>/dev/null || true
    wp core download --allow-root
    
    # Configure WordPress database connection
    echo "🔧 Configuring database connection..."
    wp core config \
        --dbhost=mariadb:3306 \
        --dbname="${MYSQL_DB}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --allow-root
    
    # Install WordPress
    echo "📦 Installing WordPress core..."
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_N}" \
        --admin_password="${WP_ADMIN_P}" \
        --admin_email="${WP_ADMIN_E}" \
        --allow-root
    
    # Create additional user
    echo "👤 Creating additional user: ${WP_U_NAME}"
    wp user create \
        "${WP_U_NAME}" \
        "${WP_U_EMAIL}" \
        --user_pass="${WP_U_PASS}" \
        --role="${WP_U_ROLE}" \
        --allow-root
    
    echo "✅ WordPress installation completed!"
    
    # Set final permissions
    chown -R www-data:www-data /var/www/wordpress
}

#=== PHP-FPM Configuration ===
configure_php_fpm() {
    echo "🔧 Configuring PHP-FPM..."
    
    # Configure PHP-FPM to listen on port 9000 instead of socket
    sed -i '36 s@/run/php/php7.4-fpm.sock@9000@' /etc/php/7.4/fpm/pool.d/www.conf
    
    # Ensure PHP run directory exists
    mkdir -p /run/php
    
    echo "✅ PHP-FPM configured for port 9000"
}

#=== Main Execution ===
main() {
    setup_debug_shell
    wait_for_database
    setup_wordpress
    configure_php_fpm
    
    echo "🚀 Starting PHP-FPM server..."
    exec /usr/sbin/php-fpm7.4 -F
}

# Run main function
main
