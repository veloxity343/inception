#!/bin/bash
set -e

echo "Starting WordPress."

# Guard clauses (must exist in environment)
: "${MYSQL_DB:?Missing MYSQL_DB}"
: "${MYSQL_USER:?Missing MYSQL_USER}"
: "${MYSQL_PASSWORD:?Missing MYSQL_PASSWORD}"
: "${DOMAIN_NAME:?Missing DOMAIN_NAME}"
: "${WP_TITLE:?Missing WP_TITLE}"
: "${WP_ADMIN_N:?Missing WP_ADMIN_N}"
: "${WP_ADMIN_P:?Missing WP_ADMIN_P}"
: "${WP_ADMIN_E:?Missing WP_ADMIN_E}"

WP_DIR="/var/www/wordpress"
WP_USER="www"
WP_GROUP="www"
WP_CONFIG_TEMPLATE="/usr/local/share/wp-config.php"

#=== Database Connection Check ===
wait_for_db() {
    echo "Waiting for MariaDB to be ready."
    local start_time=$(date +%s)
    local timeout=60
    local end_time=$((start_time + timeout))
    while [ "$(date +%s)" -lt "$end_time" ]; do
        if nc -z mariadb 3306 >/dev/null 2>&1; then
            echo "MariaDB is up and running!"
            return 0
        fi
        echo "Waiting for MariaDB to start."
        sleep 3
    done
    echo "MariaDB connection timeout after ${timeout}s"
    exit 1
}

#=== PHP-FPM Configuration ===
config_php_fpm() {
    echo "Configuring PHP 8.3-FPM."

    mkdir -p "$WP_DIR"
    chown -R "$WP_USER:$WP_GROUP" "$WP_DIR"

    sed -i 's|^listen =.*|listen = 0.0.0.0:9000|' /etc/php83/php-fpm.d/www.conf
    sed -i 's|^;*listen.owner =.*|listen.owner = www|' /etc/php83/php-fpm.d/www.conf
    sed -i 's|^;*listen.group =.*|listen.group = www|' /etc/php83/php-fpm.d/www.conf
    sed -i 's|^user =.*|user = www|' /etc/php83/php-fpm.d/www.conf
    sed -i 's|^group =.*|group = www|' /etc/php83/php-fpm.d/www.conf

    mkdir -p /run/php-fpm83
    chown www:www /run/php-fpm83

    php-fpm83 -t
    echo "PHP 8.3-FPM configured successfully"
}

# Ensure WP-CLI exists (install once in container if needed)
ensure_wp_cli() {
    if ! command -v wp >/dev/null 2>&1; then
        echo "Installing WP-CLI."
        curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x /usr/local/bin/wp
        echo "WP-CLI installed successfully"
    fi
}

#=== WordPress Installation ===
setup_wp() {
    echo "Setting up WordPress."

    cd "$WP_DIR"

    # 1) Download core files if missing (don’t delete existing volume content)
    if [ ! -f "wp-includes/version.php" ]; then
        echo "Downloading WordPress core."
        wp core download --allow-root
    else
        echo "WordPress core files already present"
    fi

    # 2) Ensure wp-config.php exists — copy our template once
    if [ ! -f "wp-config.php" ]; then
        echo "Placing wp-config.php template."
        cp "$WP_CONFIG_TEMPLATE" "$WP_DIR/wp-config.php"
        chown "$WP_USER:$WP_GROUP" "$WP_DIR/wp-config.php"
    else
        echo "wp-config.php already present, leaving as-is"
    fi

    # 3) If not installed, run the install
    if wp core is-installed --allow-root >/dev/null 2>&1; then
        echo "WordPress already installed, skipping install"
    else
        echo "Installing WordPress core."
        wp core install \
            --url="${DOMAIN_NAME}" \
            --title="${WP_TITLE}" \
            --admin_user="${WP_ADMIN_N}" \
            --admin_password="${WP_ADMIN_P}" \
            --admin_email="${WP_ADMIN_E}" \
            --skip-email \
            --allow-root
        echo "WordPress installation completed!"
    fi

    # 4) Optional additional user
    if [ -n "${WP_U_NAME:-}" ] && [ -n "${WP_U_EMAIL:-}" ] && [ -n "${WP_U_PASS:-}" ]; then
        wp user create "${WP_U_NAME}" "${WP_U_EMAIL}" \
            --user_pass="${WP_U_PASS}" \
            --role="${WP_U_ROLE:-subscriber}" \
            --allow-root || echo "Warning: Could not create user ${WP_U_NAME}"
    fi

    chown -R "$WP_USER:$WP_GROUP" "$WP_DIR"
}

#=== Optional Redis Cache Setup (idempotent & safe) ===
setup_redis() {
    cd "$WP_DIR"

    # Install plugin if missing
    if wp plugin is-installed redis-cache --allow-root 2>/dev/null; then
        echo "Redis cache plugin already installed"
    else
        echo "Installing Redis cache plugin."
        if wp plugin install redis-cache --allow-root >/dev/null 2>&1; then
            echo "Redis cache plugin installed successfully"
        else
            echo "Warning: Failed to install Redis cache plugin"
            return 0
        fi
    fi

    # Activate if not active (activation is cheap and safe)
    if wp plugin is-active redis-cache --allow-root 2>/dev/null; then
        echo "Redis cache plugin already active"
    else
        echo "Activating Redis cache plugin."
        wp plugin activate redis-cache --allow-root >/dev/null 2>&1 || echo "Warning: Could not activate Redis cache plugin"
    fi

    # Enable object cache (creates drop-in) only if Redis responds
    if nc -z redis 6379 2>/dev/null; then
        if wp redis status --allow-root 2>/dev/null | grep -q "Connected"; then
            echo "Redis cache already enabled and connected"
        else
            echo "Enabling Redis object cache."
            if wp redis enable --allow-root >/dev/null 2>&1; then
                echo "Redis cache enabled successfully"
            else
                echo "Warning: Could not enable Redis cache (will keep site running without cache)"
            fi
        fi
    else
        echo "Redis not available, skipping cache enable (site will run without caching)"
    fi
}

#=== Idempotent WordPress Content ===
setup_wp_content() {
    echo "Checking if WordPress content already exists."
    cd "$WP_DIR"

    ABOUT_EXISTS=$(wp post list --post_type=page --name=about --format=count --allow-root 2>/dev/null || echo "0")
    if [ "$ABOUT_EXISTS" -gt 0 ]; then
        echo "WordPress content already exists, skipping content creation"
        return 0
    fi

    echo "Setting up WordPress content."

    # About page
    wp post create --post_type=page --post_title='About' \
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
      --post_status=publish --allow-root >/dev/null 2>&1 || echo "Warning: Failed to create About page (may already exist)"

    # Blog page
    BLOG_EXISTS=$(wp post list --post_type=page --name=blog --format=count --allow-root 2>/dev/null || echo "0")
    if [ "$BLOG_EXISTS" -eq 0 ]; then
        wp post create --post_type=page --post_title='Blog' \
          --post_content='<p>This is the blog section where I share technical insights and project updates.</p>' \
          --post_status=publish --allow-root >/devnull 2>&1 || echo "Warning: Failed to create Blog page"
    else
        echo "Blog page already exists, skipping"
    fi

    # Contact page
    CONTACT_EXISTS=$(wp post list --post_type=page --name=contact --format=count --allow-root 2>/dev/null || echo "0")
    if [ "$CONTACT_EXISTS" -eq 0 ]; then
        wp post create --post_type=page --post_title='Contact' \
          --post_content='<h2>Get In Touch</h2>
<p>Feel free to reach out for collaboration or technical discussions!</p>

<p><strong>Email:</strong> ryan.cheongtl@gmail.com</p>
<p><strong>GitHub:</strong> <a href="https://github.com/veloxity343">GitHub</a></p>
<p><strong>Professional Portfolio:</strong> <a href="/portfolio/">View Resume</a></p>' \
          --post_status=publish --allow-root >/dev/null 2>&1 || echo "Warning: Failed to create Contact page"
    else
        echo "Contact page already exists, skipping"
    fi

    # Sample posts
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
          --post_status=publish --post_category=1 --allow-root >/dev/null 2>&1 || echo "Warning: Failed to create Docker project post"
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
          --post_status=publish --post_category=1 --allow-root >/dev/null 2>&1 || echo "Warning: Failed to create Redis caching post"
    else
        echo "Redis caching post already exists, skipping"
    fi

    echo "WordPress content setup completed"
}

#=== Idempotent WordPress Navigation ===
setup_wp_navigation() {
    echo "Setting up WordPress navigation menu."
    cd "$WP_DIR"

    EXISTING_MENU_ID=$(wp menu list --format=csv --fields=term_id,name --allow-root 2>/dev/null | grep "Main Navigation" | cut -d',' -f1 2>/dev/null || true)

    if [ -n "$EXISTING_MENU_ID" ]; then
        echo "Main Navigation menu already exists (ID: $EXISTING_MENU_ID), updating existing menu"
        MENU_ID="$EXISTING_MENU_ID"
        EXISTING_ITEMS=$(wp menu item list "$MENU_ID" --format=ids --allow-root 2>/dev/null || true)
        if [ -n "$EXISTING_ITEMS" ]; then
            for item_id in $EXISTING_ITEMS; do
                wp menu item delete "$item_id" --allow-root >/dev/null 2>&1 || echo "Warning: Could not delete menu item $item_id"
            done
        fi
    else
        echo "Creating new Main Navigation menu."
        if wp menu create "Main Navigation" --allow-root >/dev/null 2>&1; then
            MENU_ID=$(wp menu list --name="Main Navigation" --format=ids --allow-root 2>/dev/null | head -1)
            echo "New menu created (ID: $MENU_ID)"
        else
            MENU_ID=$(wp menu list --format=ids --allow-root 2>/dev/null | head -1)
            if [ -z "$MENU_ID" ]; then
                echo "No menu available, skipping navigation setup"
                return 0
            fi
        fi
    fi

    [ -z "$MENU_ID" ] && { echo "No valid menu ID, skipping navigation setup"; return 0; }

    echo "Adding pages to navigation menu."
    wp menu item add-custom "$MENU_ID" "Home" "/" --allow-root >/dev/null 2>&1 || echo "Warning: Failed to add Home link"

    ABOUT_ID=$(wp post list --post_type=page --name=about --format=ids --allow-root 2>/dev/null | head -1)
    [ -n "$ABOUT_ID" ] && wp menu item add-post "$MENU_ID" "$ABOUT_ID" --allow-root >/dev/null 2>&1 || echo "Warning: Failed to add About page"

    BLOG_ID=$(wp post list --post_type=page --name=blog --format=ids --allow-root 2>/dev/null | head -1)
    [ -n "$BLOG_ID" ] && wp menu item add-post "$MENU_ID" "$BLOG_ID" --allow-root >/dev/null 2>&1 || echo "Warning: Failed to add Blog page"

    wp menu item add-custom "$MENU_ID" "Portfolio" "/portfolio/" --allow-root >/dev/null 2>&1 || echo "Warning: Failed to add Portfolio link"

    CONTACT_ID=$(wp post list --post_type=page --name=contact --format=ids --allow-root 2>/dev/null | head -1)
    [ -n "$CONTACT_ID" ] && wp menu item add-post "$MENU_ID" "$CONTACT_ID" --allow-root >/dev/null 2>&1 || echo "Warning: Failed to add Contact page"

    echo "Attempting to assign menu to theme location."
    if wp menu location assign "$MENU_ID" primary --allow-root >/dev/null 2>&1; then
        echo "Menu assigned to primary location"
    else
        LOCATIONS=$(wp menu location list --format=csv --fields=location --allow-root 2>/dev/null | tail -n +2 | head -1 || true)
        if [ -n "$LOCATIONS" ]; then
            wp menu location assign "$MENU_ID" "$LOCATIONS" --allow-root >/dev/null 2>&1 && echo "Menu assigned to location: $LOCATIONS" || echo "Could not assign menu to any location"
        else
            echo "No menu locations available (theme may not support menus)"
        fi
    fi

    echo "Navigation menu setup completed"
}

#=== Idempotent WordPress Theme Setup ===
setup_wp_theme() {
    echo "Configuring WordPress theme."
    cd "$WP_DIR"

    CURRENT_THEME=$(wp theme status --allow-root 2>/dev/null | grep "Active:" | awk '{print $2}' || true)

    if [ "$CURRENT_THEME" != "twentytwentyfour" ]; then
        echo "Installing/activating Twenty Twenty-Four theme."
        wp theme install twentytwentyfour --allow-root >/dev/null 2>&1 || echo "Theme may already be installed"
        wp theme activate twentytwentyfour --allow-root >/dev/null 2>&1 || echo "Warning: Could not activate Twenty Twenty-Four theme"
    else
        echo "Twenty Twenty-Four theme already active"
    fi

    CURRENT_DESCRIPTION=$(wp option get blogdescription --allow-root 2>/dev/null || echo "")
    [ "$CURRENT_DESCRIPTION" != "Docker Inception Project - Full Stack Development" ] && \
      wp option update blogdescription "Docker Inception Project - Full Stack Development" --allow-root >/dev/null 2>&1 || true

    CURRENT_START_WEEK=$(wp option get start_of_week --allow-root 2>/dev/null || echo "")
    [ "$CURRENT_START_WEEK" != "1" ] && wp option update start_of_week 1 --allow-root >/dev/null 2>&1 || true

    CURRENT_TIMEZONE=$(wp option get timezone_string --allow-root 2>/dev/null || echo "")
    [ "$CURRENT_TIMEZONE" != "Asia/Kuala_Lumpur" ] && wp option update timezone_string "Asia/Kuala_Lumpur" --allow-root >/dev/null 2>&1 || true

    echo "WordPress theme configuration completed"
}

#=== Main Execution ===
main() {
    echo "=== Starting WordPress Setup ==="

    wait_for_db
    config_php_fpm
    ensure_wp_cli
    setup_wp

    echo "Starting PHP-FPM server."

    # Content, menu, theme (all idempotent / best-effort)
    echo "Setting up WordPress content and configuration."
    {
        setup_redis
        sleep 5
        setup_wp_content
        setup_wp_navigation
        setup_wp_theme
    } &
    echo "WordPress content setup completed"

    echo "Setting final permissions."
    chown -R "$WP_USER:$WP_GROUP" "$WP_DIR"
    find "$WP_DIR" -type d -exec chmod 755 {} \;
    find "$WP_DIR" -type f -exec chmod 644 {} \;

    # ready marker
    touch "$WP_DIR/.wp_ready"
    echo "WordPress setup completed - ready for connections"

    exec /usr/sbin/php-fpm83 -F
}

trap 'echo "Received shutdown signal, stopping PHP-FPM."; pkill -TERM php-fpm83; exit 0' SIGTERM SIGINT
main
