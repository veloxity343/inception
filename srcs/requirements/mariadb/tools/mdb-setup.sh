#!/bin/sh
set -e

echo "Starting MariaDB setup."

# Ensure runtime + data dirs exist and are writable by mysql
mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Bootstrap on first run only
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initialising MariaDB data directory."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql
  
  echo "Creating initialisation SQL file."
  cat > /tmp/init.sql <<EOF
-- Security cleanup
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create WordPress database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create WordPress user with all necessary host patterns
CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Grant privileges to WordPress user
GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.* TO \`${MYSQL_USER}\`@'localhost';
GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.* TO \`${MYSQL_USER}\`@'%';
GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.* TO \`${MYSQL_USER}\`@'127.0.0.1';

-- Allow root from containers (for debugging)
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

-- Apply changes
FLUSH PRIVILEGES;
EOF
  
  echo "MariaDB data directory initialised with setup SQL"
else
  echo "MariaDB data directory already exists, skipping initialisation."
fi

echo "Starting MariaDB server."
# Use --init-file to run our setup SQL on first start
if [ -f /tmp/init.sql ]; then
  echo "Running initialisation SQL on startup."
  exec mariadbd --defaults-file=/etc/my.cnf.d/mdb.conf --user=mysql --init-file=/tmp/init.sql
else
  exec mariadbd --defaults-file=/etc/my.cnf.d/mdb.conf --user=mysql
fi
