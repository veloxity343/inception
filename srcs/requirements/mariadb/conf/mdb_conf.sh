#!/bin/bash
set -e

echo "Starting MariaDB."
mysqld_safe --port=3306 --bind-address=0.0.0.0 --datadir='/var/lib/mysql' &
pid="$!"
# service mariadb start

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to start..."
for i in {1..30}; do
	if mysqladmin ping &>/dev/null; then
		echo "MariaDB is ready!"
		break
	fi
	echo "Waiting... ($i/30)"
	sleep 1
done

# Check if MariaDB started successfully
if ! mysqladmin ping &>/dev/null; then
	echo "ERROR: MariaDB failed to start"
	exit 1
fi

# MariaDB security setup - set root password
echo "Setting up root password."
mysqladmin -u root password "$MYSQL_ROOT_PASSWORD" 2>/dev/null || echo "Root password already set"

# Remove anonymous users and test database
echo "Securing MariaDB installation."
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true

# MariaDB configuration - create WordPress database and user
echo "Creating WordPress database and user."
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\`;"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.* TO \`${MYSQL_USER}\`@'%';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

echo "Database '${MYSQL_DB}' and user '${MYSQL_USER}' created successfully"

# Start MariaDB in foreground
echo "MariaDB is now running in foreground."
wait "$pid"

# Restart MariaDB for production
# echo "Restarting MariaDB for production mode..."
# mysqladmin -u root -p$MYSQL_ROOT_PASSWORD shutdown

# echo "Starting MariaDB in production mode."
# exec mysqld_safe --port=3306 --bind-address=0.0.0.0 --datadir='/var/lib/mysql'
