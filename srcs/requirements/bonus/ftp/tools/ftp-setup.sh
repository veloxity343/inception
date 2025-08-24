#!/bin/bash
set -e

echo "Setting up FTP server..."

# Create FTP user with password from environment
echo "${FTP_USER}:${FTP_PASS}" | chpasswd
echo "FTP user ${FTP_USER} configured"

# Set up FTP directory permissions
chown -R ${FTP_USER}:${FTP_USER} /var/ftp
chmod -R 755 /var/ftp

echo "Starting vsftpd server..."
exec /usr/sbin/vsftpd /etc/vsftpd.conf
