#!/bin/bash
set -e

echo "Starting WordPress."

# Guard clauses
: "${MYSQL_DB:?Missing MYSQL_DB}"
: "${MYSQL_USER:?Missing MYSQL_USER}"
: "${MYSQL_PASSWORD:?Missing MYSQL_PASSWORD}"
: "${DOMAIN_NAME:?Missing DOMAIN_NAME}"
: "${WP_TITLE:?Missing WP_TITLE}"
: "${WP_ADMIN_N:?Missing WP_ADMIN_N}"
: "${WP_ADMIN_P:?Missing WP_ADMIN_P}"
: "${WP_ADMIN_E:?Missing WP_ADMIN_E}"

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
    echo "Configuring PHP 8.3-FPM..."
    
    # Create WordPress directory early
    mkdir -p /var/www/wordpress
    chown -R www:www /var/www/wordpress
    
    # Configure PHP-FPM pool (Alpine uses php83)
    sed -i 's|^listen =.*|listen = 0.0.0.0:9000|' /etc/php83/php-fpm.d/www.conf
    sed -i 's|^;*listen.owner =.*|listen.owner = www|' /etc/php83/php-fpm.d/www.conf
    sed -i 's|^;*listen.group =.*|listen.group = www|' /etc/php83/php-fpm.d/www.conf
    sed -i 's|^user =.*|user = www|' /etc/php83/php-fpm.d/www.conf
    sed -i 's|^group =.*|group = www|' /etc/php83/php-fpm.d/www.conf

    # Ensure PHP run directory exists with proper permissions
    mkdir -p /run/php-fpm83
    chown www:www /run/php-fpm83
    
    # Test PHP-FPM config
    php-fpm83 -t
    
    echo "PHP 8.3-FPM configured successfully"
}

#=== WordPress Installation ===
setup_wp() {
    echo "Setting up WordPress..."
    
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
    if [ -n "${WP_U_NAME}" ] && [ -n "${WP_U_EMAIL}" ] && [ -n "${WP_U_PASS}" ]; then
        wp user create "${WP_U_NAME}" "${WP_U_EMAIL}" \
            --user_pass="${WP_U_PASS}" \
            --role="${WP_U_ROLE:-subscriber}" \
            --allow-root || echo "Warning: Could not create user ${WP_U_NAME}"
    fi

    echo "WordPress installation completed!"
    
    # Set final permissions
    chown -R www:www /var/www/wordpress
}

#=== WordPress Content Setup ===
setup_wp_content() {
    echo "Checking if WordPress content already exists..."
    
    cd /var/www/wordpress
    
    # Check if our custom pages already exist
    ABOUT_EXISTS=$(wp post list --post_type=page --name=about --format=count --allow-root 2>/dev/null || echo "0")
    if [ "$ABOUT_EXISTS" -gt 0 ]; then
        echo "WordPress content already exists, skipping content creation"
        return 0
    fi

    echo "Setting up WordPress content..."
    
    # Create essential pages with error handling
    echo "Creating WordPress pages..."
    
    # About page
    if wp post create --post_type=page --post_title='About' \
        --post_content='<h2>About This Site</h2>
<p>Welcome to my WordPress blog! This site demonstrates a complete Docker containerisation setup with multiple services.</p>

<h3>Technical Architecture</h3>
<ul>
<li><strong>WordPress</strong> - Content Management System (PHP 8.2 + MySQL)</li>
<li><strong>Nginx</strong> - Reverse proxy with SSL/TLS</li>
<li><strong>MariaDB</strong> - Database backend</li>
<li><strong>Redis</strong> - Caching layer for performance</li>
<li><strong>Portfolio</strong> - Static Node.js site (non-PHP)</li>
</ul>

<p>Check out my <a href="/portfolio/">professional portfolio</a> to see my technical skills and projects!</p>' \
        --post_status=publish --allow-root 2>/dev/null; then
        echo "About page created successfully"
    else
        echo "Warning: Failed to create About page (may already exist)"
    fi

    # Blog page  
    BLOG_EXISTS=$(wp post list --post_type=page --name=blog --format=count --allow-root 2>/dev/null || echo "0")
    if [ "$BLOG_EXISTS" -eq 0 ]; then
        if wp post create --post_type=page --post_title='Blog' \
            --post_content='<p>This is the blog section where I share technical insights and project updates.</p>' \
            --post_status=publish --allow-root 2>/dev/null; then
            echo "Blog page created successfully"  
        else
            echo "Warning: Failed to create Blog page"
        fi
    else
        echo "Blog page already exists, skipping"
    fi
    
    # Contact page
    CONTACT_EXISTS=$(wp post list --post_type=page --name=contact --format=count --allow-root 2>/dev/null || echo "0")
    if [ "$CONTACT_EXISTS" -eq 0 ]; then
        if wp post create --post_type=page --post_title='Contact' \
            --post_content='<h2>Get In Touch</h2>
<p>Feel free to reach out for collaboration or technical discussions!</p>

<p><strong>Email:</strong> ryan.cheongtl@gmail.com</p>
<p><strong>GitHub:</strong> <a href="https://github.com/veloxity343">GitHub</a></p>
<p><strong>Professional Portfolio:</strong> <a href="/portfolio/">View Resume</a></p>' \
            --post_status=publish --allow-root 2>/dev/null; then
            echo "Contact page created successfully"
        else
            echo "Warning: Failed to create Contact page"
        fi
    else
        echo "Contact page already exists, skipping"
    fi

    # Create sample blog posts only if they don't exist
    DOCKER_POST_EXISTS=$(wp post list --name=docker-inception-project-complete --format=count --allow-root 2>/dev/null || echo "0")
    if [ "$DOCKER_POST_EXISTS" -eq 0 ]; then
        wp post create --post_title='Docker Inception Project Complete!' \
            --post_content='<p>Successfully completed the Docker Inception project with a full containerised infrastructure:</p>

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
            --post_status=publish --post_category=1 --allow-root 2>/dev/null || echo "Warning: Failed to create Docker project post"
    else
        echo "Docker project post already exists, skipping"
    fi

    REDIS_POST_EXISTS=$(wp post list --name=wordpress-with-redis-caching --format=count --allow-root 2>/dev/null || echo "0")
    if [ "$REDIS_POST_EXISTS" -eq 0 ]; then
        wp post create --post_title='WordPress with Redis Caching' \
            --post_content='<p>Implemented Redis object caching for WordPress to improve performance:</p>

<ul>
<li>Redis server running in dedicated container</li>
<li>WordPress Redis plugin automatically configured</li>
<li>Significant performance improvements for dynamic content</li>
</ul>

<p>The setup demonstrates proper service orchestration with Docker Compose.</p>' \
            --post_status=publish --post_category=1 --allow-root 2>/dev/null || echo "Warning: Failed to create Redis caching post"
    else
        echo "Redis caching post already exists, skipping"
    fi
    
    echo "WordPress content setup completed"
}

#=== WordPress Navigation ===
setup_wp_navigation() {
    echo "Setting up WordPress navigation menu..."
    
    cd /var/www/wordpress
    
    # Check if "Main Navigation" menu already exists
    EXISTING_MENU_ID=$(wp menu list --format=csv --fields=term_id,name --allow-root 2>/dev/null | grep "Main Navigation" | cut -d',' -f1 2>/dev/null || echo "")
    
    if [ -n "$EXISTING_MENU_ID" ]; then
        echo "Main Navigation menu already exists (ID: $EXISTING_MENU_ID), updating existing menu"
        MENU_ID="$EXISTING_MENU_ID"
        
        # Clear existing menu items to avoid duplicates
        echo "Clearing existing menu items..."
        EXISTING_ITEMS=$(wp menu item list "$MENU_ID" --format=ids --allow-root 2>/dev/null || echo "")
        if [ -n "$EXISTING_ITEMS" ]; then
            for item_id in $EXISTING_ITEMS; do
                wp menu item delete "$item_id" --allow-root 2>/dev/null || echo "Warning: Could not delete menu item $item_id"
            done
        fi
    else
        echo "Creating new Main Navigation menu..."
        if wp menu create "Main Navigation" --allow-root 2>/dev/null; then
            MENU_ID=$(wp menu list --name="Main Navigation" --format=ids --allow-root 2>/dev/null | head -1)
            echo "New menu created (ID: $MENU_ID)"
        else
            echo "Failed to create menu, attempting to find existing menu"
            MENU_ID=$(wp menu list --format=ids --allow-root 2>/dev/null | head -1)
            if [ -z "$MENU_ID" ]; then
                echo "No menu available, skipping navigation setup"
                return 0
            fi
        fi
    fi
    
    # Only proceed if we have a valid menu ID
    if [ -z "$MENU_ID" ]; then
        echo "No valid menu ID, skipping navigation setup"
        return 0
    fi
    
    echo "Setting up menu items for menu ID: $MENU_ID"
    
    # Add pages to menu with error handling (don't exit on failure)
    echo "Adding pages to navigation menu..."
    
    # Home
    wp menu item add-custom "$MENU_ID" "Home" "/" --allow-root 2>/dev/null || echo "Warning: Failed to add Home link"
    
    # About  
    ABOUT_ID=$(wp post list --post_type=page --name=about --format=ids --allow-root 2>/dev/null | head -1)
    if [ -n "$ABOUT_ID" ]; then
        wp menu item add-post "$MENU_ID" "$ABOUT_ID" --allow-root 2>/dev/null || echo "Warning: Failed to add About page"
    else
        echo "About page not found, skipping"
    fi
    
    # Blog
    BLOG_ID=$(wp post list --post_type=page --name=blog --format=ids --allow-root 2>/dev/null | head -1)
    if [ -n "$BLOG_ID" ]; then
        wp menu item add-post "$MENU_ID" "$BLOG_ID" --allow-root 2>/dev/null || echo "Warning: Failed to add Blog page"
    else
        echo "Blog page not found, skipping"
    fi
    
    # Portfolio (external link to static site)
    wp menu item add-custom "$MENU_ID" "Portfolio" "/portfolio/" --allow-root 2>/dev/null || echo "Warning: Failed to add Portfolio link"
    
    # Contact
    CONTACT_ID=$(wp post list --post_type=page --name=contact --format=ids --allow-root 2>/dev/null | head -1)
    if [ -n "$CONTACT_ID" ]; then
        wp menu item add-post "$MENU_ID" "$CONTACT_ID" --allow-root 2>/dev/null || echo "Warning: Failed to add Contact page"
    else
        echo "Contact page not found, skipping"
    fi
    
    # Try to assign menu to theme location (but don't fail if it doesn't work)
    echo "Attempting to assign menu to theme location..."
    if wp menu location assign "$MENU_ID" primary --allow-root 2>/dev/null; then
        echo "Menu assigned to primary location"
    else
        # Try alternative location names
        LOCATIONS=$(wp menu location list --format=csv --fields=location --allow-root 2>/dev/null | tail -n +2 | head -1 || echo "")
        if [ -n "$LOCATIONS" ]; then
            wp menu location assign "$MENU_ID" "$LOCATIONS" --allow-root 2>/dev/null && echo "Menu assigned to location: $LOCATIONS" || echo "Could not assign menu to any location"
        else
            echo "No menu locations available (theme may not support menus)"
        fi
    fi
    
    echo "Navigation menu setup completed"
}

#=== WordPress Theme Setup ===  
setup_wp_theme() {
    echo "Configuring WordPress theme..."
    
    cd /var/www/wordpress
    
    # Check current theme
    CURRENT_THEME=$(wp theme status --allow-root 2>/dev/null | grep "Active:" | cut -d' ' -f2 || echo "")
    
    # Install and activate Twenty Twenty-Four if not already active
    if [ "$CURRENT_THEME" != "twentytwentyfour" ]; then
        echo "Installing/activating Twenty Twenty-Four theme..."
        if wp theme install twentytwentyfour --allow-root 2>/dev/null; then
            echo "Twenty Twenty-Four installed successfully"
        else
            echo "Theme may already be installed"
        fi
        
        if wp theme activate twentytwentyfour --allow-root 2>/dev/null; then
            echo "Twenty Twenty-Four activated successfully"
        else
            echo "Warning: Could not activate Twenty Twenty-Four theme"
        fi
    else
        echo "Twenty Twenty-Four theme already active"
    fi
    
    # Set up basic customization (only if not already set)
    CURRENT_DESCRIPTION=$(wp option get blogdescription --allow-root 2>/dev/null || echo "")
    if [ "$CURRENT_DESCRIPTION" != "Docker Inception Project - Full Stack Development" ]; then
        wp option update blogdescription "Docker Inception Project - Full Stack Development" --allow-root 2>/dev/null || echo "Warning: Could not update blog description"
    else
        echo "Blog description already configured"
    fi
    
    # Set start of week (only if not already set)
    CURRENT_START_WEEK=$(wp option get start_of_week --allow-root 2>/dev/null || echo "")
    if [ "$CURRENT_START_WEEK" != "1" ]; then
        wp option update start_of_week 1 --allow-root 2>/dev/null || echo "Warning: Could not update start of week"
    else
        echo "Start of week already configured"
    fi
    
    # Set timezone (only if not already set)
    CURRENT_TIMEZONE=$(wp option get timezone_string --allow-root 2>/dev/null || echo "")
    if [ "$CURRENT_TIMEZONE" != "Asia/Kuala_Lumpur" ]; then
        wp option update timezone_string "Asia/Kuala_Lumpur" --allow-root 2>/dev/null || echo "Warning: Could not update timezone"
    else
        echo "Timezone already configured"
    fi
    
    echo "WordPress theme configuration completed"
}

#=== Redis Cache Setup ===
setup_redis() {
    if nc -z redis 6379 2>/dev/null; then
        echo "Redis detected, configuring cache..."
        
        cd /var/www/wordpress
        
        # Check if Redis plugin is already installed
        if wp plugin is-installed redis-cache --allow-root 2>/dev/null; then
            echo "Redis cache plugin already installed"
        else
            echo "Installing Redis cache plugin..."
            if wp plugin install redis-cache --allow-root 2>/dev/null; then
                echo "Redis cache plugin installed successfully"
            else
                echo "Warning: Failed to install Redis cache plugin"
                return 0
            fi
        fi
        
        # Check if plugin is already active
        if wp plugin is-active redis-cache --allow-root 2>/dev/null; then
            echo "Redis cache plugin already active"
        else
            echo "Activating Redis cache plugin..."
            wp plugin activate redis-cache --allow-root 2>/dev/null || echo "Warning: Could not activate Redis cache plugin"
        fi

        echo "Configuring WordPress to use Redis..."
        
        # Set Redis configuration (these commands are idempotent)
        wp config set WP_REDIS_HOST 'redis' --allow-root 2>/dev/null || echo "Warning: Could not set Redis host"
        wp config set WP_REDIS_PORT 6379 --allow-root 2>/dev/null || echo "Warning: Could not set Redis port"
        wp config set WP_REDIS_DATABASE 0 --allow-root 2>/dev/null || echo "Warning: Could not set Redis database"
        wp config set WP_REDIS_TIMEOUT 1 --allow-root 2>/dev/null || echo "Warning: Could not set Redis timeout"
        wp config set WP_REDIS_READ_TIMEOUT 1 --allow-root 2>/dev/null || echo "Warning: Could not set Redis read timeout"
        
        # Enable Redis object cache (check if already enabled first)
        if wp redis status --allow-root 2>/dev/null | grep -q "Connected"; then
            echo "Redis cache already enabled and connected"
        else
            echo "Enabling Redis object cache..."
            if wp redis enable --allow-root 2>/dev/null; then
                echo "Redis cache enabled successfully"
            else
                echo "Warning: Could not enable Redis cache"
            fi
        fi
        
        echo "Redis cache configuration completed"
    else
        echo "Redis not available, skipping cache setup"
    fi
}

#=== Main Execution ===
main() {
    echo "=== Starting WordPress Setup ==="
    
    # Wait for database
    wait_for_db
    
    # Configure PHP-FPM
    config_php_fpm
    
    # Setup WordPress core
    setup_wp

    # Setup content
    echo "Setting up WordPress content and configuration..."
    {
        sleep 5
        setup_wp_content
        setup_wp_navigation
        setup_wp_theme
        setup_redis
    } &
    echo "WordPress content setup completed"
    
    # Final permissions
    echo "Setting final permissions..."
    chown -R www:www /var/www/wordpress
    find /var/www/wordpress -type d -exec chmod 755 {} \;
    find /var/www/wordpress -type f -exec chmod 644 {} \;


    # Create ready signal
    touch /var/www/wordpress/.wp_ready
    echo "WordPress setup completed - ready for connections"

    echo "Starting PHP-FPM server."
    exec /usr/sbin/php-fpm83 -F
}

# Trap signals to ensure clean shutdown
trap 'echo "Received shutdown signal, stopping PHP-FPM."; pkill -TERM php-fpm83; exit 0' SIGTERM SIGINT

# Run main function
main
