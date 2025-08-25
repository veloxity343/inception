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
    
    # Create essential pages
    echo "Creating WordPress pages..."
    
    # About page
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

    # Blog page  
    wp post create --post_type=page --post_title='Blog' \
        --post_content='<p>This is the blog section where I share technical insights and project updates.</p>' \
        --post_status=publish --allow-root
    
    # Contact page
    wp post create --post_type=page --post_title='Contact' \
        --post_content='<h2>Get In Touch</h2>
<p>Feel free to reach out for collaboration or technical discussions!</p>

<p><strong>Email:</strong> ryan.cheongtl@gmail.com</p>
<p><strong>GitHub:</strong> Coming soon...</p>
<p><strong>Professional Portfolio:</strong> <a href="/portfolio/">View Resume</a></p>' \
        --post_status=publish --allow-root

    # Create sample blog posts
    echo "Creating sample blog posts..."
    
    wp post create --post_title='Docker Inception Project Complete!' \
        --post_content='<p>Successfully completed the Docker Inception project with a full containerized infrastructure:</p>

<h3>Core Services</h3>
<ul>
<li>Nginx reverse proxy with SSL</li>
<li>WordPress CMS with PHP-FPM</li>  
<li>MariaDB database</li>
</ul>

<h3>Bonus Services</h3>
<ul>
<li>Redis caching for WordPress</li>
<li>FTP server for file management</li>
<li>Adminer for database administration</li>
<li>Portainer for container management</li>
<li>Static portfolio site (Node.js)</li>
</ul>

<p>Check out the technical details in my <a href="/portfolio/">portfolio</a>!</p>' \
        --post_status=publish --post_category=1 --allow-root

    wp post create --post_title='WordPress with Redis Caching' \
        --post_content='<p>Implemented Redis object caching for WordPress to improve performance:</p>

<ul>
<li>Redis server running in dedicated container</li>
<li>WordPress Redis plugin automatically configured</li>
<li>Significant performance improvements for dynamic content</li>
</ul>

<p>The setup demonstrates proper service orchestration with Docker Compose.</p>' \
        --post_status=publish --post_category=1 --allow-root
    
    echo "WordPress content created successfully!"
}

#=== WordPress Navigation ===
setup_wp_navigation() {
    echo "Setting up WordPress navigation menu..."
    
    # Create main navigation menu
    wp menu create "Main Navigation" --allow-root
    
    # Get the menu ID
    MENU_ID=$(wp menu list --format=ids --allow-root | head -1)
    
    # Add pages to menu
    echo "Adding pages to navigation menu..."
    
    # Home
    wp menu item add-custom "$MENU_ID" "Home" "/" --allow-root
    
    # About  
    ABOUT_ID=$(wp post list --post_type=page --name=about --format=ids --allow-root)
    wp menu item add-post "$MENU_ID" "$ABOUT_ID" --allow-root
    
    # Blog
    BLOG_ID=$(wp post list --post_type=page --name=blog --format=ids --allow-root)  
    wp menu item add-post "$MENU_ID" "$BLOG_ID" --allow-root
    
    # Portfolio (external link to static site)
    wp menu item add-custom "$MENU_ID" "Portfolio" "/portfolio/" --allow-root
    
    # Contact
    CONTACT_ID=$(wp post list --post_type=page --name=contact --format=ids --allow-root)
    wp menu item add-post "$MENU_ID" "$CONTACT_ID" --allow-root
    
    # Assign menu to primary location
    wp menu location assign "$MENU_ID" primary --allow-root
    
    echo "Navigation menu configured successfully!"
}

#=== WordPress Theme Setup ===  
setup_wp_theme() {
    echo "Configuring WordPress theme..."
    
    # Install and activate a modern theme (Twenty Twenty-Four)
    wp theme install twentytwentyfour --activate --allow-root || echo "Theme already exists"
    
    # Set up basic customization
    wp option update blogdescription "Docker Inception Project - Full Stack Development" --allow-root
    wp option update start_of_week 1 --allow-root
    wp option update timezone_string "Asia/Kuala_Lumpur" --allow-root
    
    echo "WordPress theme configured!"
}

#=== Redis Cache Setup ===
setup_redis() {
    if nc -z redis 6379 2>/dev/null; then
        echo "Redis detected, enabling cache..."
        wp plugin install redis-cache --activate --allow-root

        echo "Configuring WordPress to use Redis..."
        
        wp config set WP_REDIS_HOST 'redis' --allow-root
        wp config set WP_REDIS_PORT 6379 --allow-root
        wp config set WP_REDIS_DATABASE 0 --allow-root
        wp config set WP_REDIS_TIMEOUT 1 --allow-root
        wp config set WP_REDIS_READ_TIMEOUT 1 --allow-root
        
        # Enable Redis object cache
        wp redis enable --allow-root
        
        echo "Redis cache configured successfully!"
    else
        echo "Redis not available, skipping cache setup"
    fi
}

#=== PHP-FPM Configuration ===
config_php_fpm() {
    echo "Configuring PHP 8.2-FPM..."
    
    # Configure PHP-FPM to listen on port 9000 instead of socket
    sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf
    
    # Ensure PHP run directory exists
    mkdir -p /run/php
    
    echo "PHP 8.2-FPM configured for port 9000"
}

#=== Main Execution ===
main() {
    wait_for_db
    setup_wp
    setup_wp_content
    setup_wp_navigation
    setup_wp_theme 
    setup_redis
    config_php_fpm
    
    echo "Starting PHP 8.2-FPM server..."
    exec /usr/sbin/php-fpm8.2 -F
}

# Run main function
main
