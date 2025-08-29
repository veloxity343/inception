#!/bin/sh
set -e

echo "Starting MariaDB setup."

# Bootstrap
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "Running bootstrap SQL setup..."
    mysqld --user=mysql --datadir=/var/lib/mysql --bootstrap <<EOSQL
        -- Set root password
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

        -- Remove anonymous users
        DELETE FROM mysql.user WHERE User='';

        -- Remove test database
        DROP DATABASE IF EXISTS test;

        -- Create WordPress database and user
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\`;
        CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.* TO \`${MYSQL_USER}\`@'%';
        FLUSH PRIVILEGES;
EOSQL
else
    echo "MariaDB data directory already exists, skipping initialization."
fi

echo "MariaDB setup complete. Starting in foreground..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --port=3306 --bind-address=0.0.0.0
