#!/bin/sh
set -e

echo "Starting MariaDB setup."

# Ensure runtime + data dirs exist and are writable by mysql
mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Bootstrap on first run only
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing MariaDB data directory..."
  mysql_install_db --user=mysql --datadir=/var/lib/mysql

  echo "Running bootstrap SQL setup..."
  mariadbd --user=mysql --datadir=/var/lib/mysql --bootstrap <<EOSQL
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
exec mariadbd --user=mysql --datadir=/var/lib/mysql
