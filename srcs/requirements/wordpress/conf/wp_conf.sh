#!/bin/bash
set -e

echo "Starting WordPress."

#=== Database Connection Check ===
wait_for_db() {
    echo "Waiting for MariaDB to be ready..."
    
    local start_time=$(date +%s)
    local timeout=60
    local end_time=$((start_time + timeout))
    
    while [ $(date +%s) -lt $end_time ]; do
        if nc -z mariadb 3306 >/dev/null 2>&1; then
            echo "MariaDB is up and running!"
            return 0
        else
            echo "Waiting for MariaDB to start..."
            sleep 3
        fi
    done
    
    echo "MariaDB connection timeout after ${timeout}s"
    exit 1
}

#=== PHP-FPM Configuration ===
config_php_fpm() {
    echo "Configuring PHP 8.2-FPM..."
    
    # Configure PHP-FPM to listen on all interfaces port 9000
    sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 0.0.0.0:9000|' /etc/php/8.2/fpm/pool.d/www.conf
    
    # Additional PHP-FPM configuration for better Docker compatibility
    echo "listen.owner = www-data" >> /etc/php/8.2/fpm/pool.d/www.conf
    echo "listen.group = www-data" >> /etc/php/8.2/fpm/pool.d/www.conf
    echo "listen.mode = 0660" >> /etc/php/8.2/fpm/pool.d/www.conf
    
    # Ensure PHP-FPM runs in foreground
    sed -i 's|;daemonize = yes|daemonize = no|' /etc/php/8.2/fpm/php-fpm.conf
    
    # Configure process management
    sed -i 's|pm.max_children = 5|pm.max_children = 20|' /etc/php/8.2/fpm/pool.d/www.conf
    sed -i 's|pm.start_servers = 2|pm.start_servers = 3|' /etc/php/8.2/fpm/pool.d/www.conf
    sed -i 's|pm.min_spare_servers = 1|pm.min_spare_servers = 2|' /etc/php/8.2/fpm/pool.d/www.conf
    sed -i 's|pm.max_spare_servers = 3|pm.max_spare_servers = 4|' /etc/php/8.2/fpm/pool.d/www.conf
    
    # Enable error logging
    sed -i 's|;catch_workers_output = yes|catch_workers_output = yes|' /etc/php/8.2/fpm/pool.d/www.conf
    
    # Ensure PHP run directory exists
    mkdir -p /run/php
    chown www-data:www-data /run/php
    
    echo "PHP 8.2-FPM configured for port 9000"
}

#=== WordPress Installation ===
setup_wp() {
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
        echo "WordPress already installed, skipping setup"
        return 0
    fi
    
    echo "Installing WordPress..."
    
    # Clean directory and download WordPress
    find /var/www/wordpress/ -mindepth 1 -delete 2>/dev/null || true
    wp core download --allow-root
    
    # Configure WordPress database connection
    echo "Configuring database connection..."
    wp core config \
        --dbhost=mariadb:3306 \
        --dbname="${MYSQL_DB}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --allow-root
    
    # Install WordPress
    echo "Installing WordPress core..."
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_N}" \
        --admin_password="${WP_ADMIN_P}" \
        --admin_email="${WP_ADMIN_E}" \
        --allow-root
    
    # Create additional user
    echo "Creating additional user: ${WP_U_NAME}"
    wp user create \
        "${WP_U_NAME}" \
        "${WP_U_EMAIL}" \
        --user_pass="${WP_U_PASS}" \
        --role="${WP_U_ROLE}" \
        --allow-root
    
    echo "WordPress installation completed!"
    
    # Set final permissions
    chown -R www-data:www-data /var/www/wordpress
}

#=== WordPress Content Setup ===
setup_wp_content() {
    echo "Setting up WordPress content and navigation..."
    
    # Skip if already set up (check for a marker)
    if wp option get wp_content_setup_done --allow-root >/dev/null 2>&1; then
        echo "WordPress content already set up, skipping..."
        return 0
    fi
    
    # Create essential pages only if they don't exist
    echo "Creating WordPress pages..."
    
    # About page
    if ! wp post list --post_type=page --name=about --format=count --allow-root | grep -q "1"; then
        wp post create --post_type=page --post_title='About' \
            --post_content='<h2>About This Site</h2>
<p>Welcome to my WordPress blog! This site demonstrates a complete Docker containerization setup with multiple services.</p>

<h3>Technical Architecture</h3>
<ul>
<li><strong>WordPress</strong> - Content Management System (PHP 8.2 + MySQL)</li>
<li><strong>Nginx</strong> - Reverse proxy with SSL/TLS</li>
<li><strong>MariaDB</strong> - Database backend</li>
<li><strong>Redis</strong> - Caching layer for performance</li>
<li><strong>Portfolio</strong> - Static Node.js site (non-PHP)</li>
</ul>

<p>Check out my <a href="/portfolio/">professional portfolio</a> to see my technical skills and projects!</p>' \
            --post_status=publish --allow-root
    fi

    # Blog page  
    if ! wp post list --post_type=page --name=blog --format=count --allow-root | grep -q "1"; then
        wp post create --post_type=page --post_title='Blog' \
            --post_content='<p>This is the blog section where I share technical insights and project updates.</p>' \
            --post_status=publish --allow-root
    fi
    
    # Contact page
    if ! wp post list --post_type=page --name=contact --format=count --allow-root | grep -q "1"; then
        wp post create --post_type=page --post_title='Contact' \
            --post_content='<h2>Get In Touch</h2>
<p>Feel free to reach out for collaboration or technical discussions!</p>

<p><strong>Email:</strong> ryan.cheongtl@gmail.com</p>
<p><strong>GitHub:</strong> Coming soon...</p>
<p><strong>Professional Portfolio:</strong> <a href="/portfolio/">View Resume</a></p>' \
            --post_status=publish --allow-root
    fi

    # Create sample blog posts only if none exist
    POST_COUNT=$(wp post list --post_type=post --format=count --allow-root)
    if [ "$POST_COUNT" -eq 1 ]; then  # Only default "Hello World" post
        echo "Creating sample blog posts..."
        
        wp post create --post_title='Docker Inception Project Complete!' \
            --post_content='<p>Successfully completed the Docker Inception project with a full containerized infrastructure.</p>' \
            --post_status=publish --post_category=1 --allow-root

        wp post create --post_title='WordPress with Redis Caching' \
            --post_content='<p>Implemented Redis object caching for WordPress to improve performance.</p>' \
            --post_status=publish --post_category=1 --allow-root
    fi
    
    # Set marker to avoid re-running
    wp option add wp_content_setup_done "1" --allow-root
    echo "WordPress content created successfully!"
}

#=== WordPress Navigation Setup ===
setup_wp_navigation() {
    echo "Setting up WordPress navigation menu..."
    
    # Skip if already set up
    if wp menu list --format=count --allow-root | grep -q -v "0"; then
        echo "Navigation menu already exists, skipping..."
        return 0
    fi
    
    # Create main navigation menu with unique name
    MENU_NAME="Main-Nav-$(date +%s)"
    wp menu create "$MENU_NAME" --allow-root
    
    # Get the menu ID
    MENU_ID=$(wp menu list --format=ids --allow-root | head -1)
    
    if [ -n "$MENU_ID" ]; then
        echo "Adding pages to navigation menu..."
        
        # Add menu items (ignore errors)
        wp menu item add-custom "$MENU_ID" "Home" "/" --allow-root || true
        wp menu item add-custom "$MENU_ID" "Portfolio" "/portfolio/" --allow-root || true
        
        echo "Navigation menu configured successfully!"
    fi
}

#=== WordPress Theme Setup ===  
setup_wp_theme() {
    echo "Configuring WordPress theme..."
    
    # Skip if already configured
    if wp option get wp_theme_setup_done --allow-root >/dev/null 2>&1; then
        echo "WordPress theme already configured, skipping..."
        return 0
    fi
    
    # Install and activate a modern theme (Twenty Twenty-Four)
    wp theme install twentytwentyfour --activate --allow-root 2>/dev/null || echo "Theme already exists"
    
    # Set up basic customization
    wp option update blogdescription "Docker Inception Project - Full Stack Development" --allow-root
    wp option update start_of_week 1 --allow-root
    wp option update timezone_string "Asia/Kuala_Lumpur" --allow-root
    
    # Set marker
    wp option add wp_theme_setup_done "1" --allow-root
    echo "WordPress theme configured!"
}

#=== Redis Cache Setup ===
setup_redis() {
    if nc -z redis 6379 2>/dev/null; then
        echo "Redis detected, enabling cache..."
        
        # Check if plugin already installed
        if ! wp plugin is-installed redis-cache --allow-root; then
            wp plugin install redis-cache --activate --allow-root

            echo "Configuring WordPress to use Redis..."
            
            wp config set WP_REDIS_HOST 'redis' --allow-root
            wp config set WP_REDIS_PORT 6379 --allow-root
            wp config set WP_REDIS_DATABASE 0 --allow-root
            wp config set WP_REDIS_TIMEOUT 1 --allow-root
            wp config set WP_REDIS_READ_TIMEOUT 1 --allow-root
            
            # Enable Redis object cache
            wp redis enable --allow-root || echo "Redis cache already enabled"
            
            echo "Redis cache configured successfully!"
        else
            echo "Redis cache already installed and configured"
        fi
    else
        echo "Redis not available, skipping cache setup"
    fi
}

#=== Main Execution ===
main() {
    # Configure PHP-FPM FIRST before anything else
    config_php_fpm
    
    wait_for_db
    setup_wp
    
    # Only run content setup on first run or if forced
    if [ "${FORCE_WP_SETUP:-false}" = "true" ] || ! wp option get wp_initial_setup_done --allow-root >/dev/null 2>&1; then
        setup_wp_content
        setup_wp_navigation  
        setup_wp_theme
        wp option add wp_initial_setup_done "1" --allow-root
        echo "Initial WordPress setup completed!"
    else
        echo "WordPress already fully configured, skipping content setup"
    fi
    
    setup_redis
    
    echo "Starting PHP 8.2-FPM server..."
    exec /usr/sbin/php-fpm8.2 -F
}

# Run main function
main
