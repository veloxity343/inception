#!/bin/sh
set -e

echo "Setting up FTP server."

# Ensure secure chroot dir exists
mkdir -p /var/run/vsftpd/empty
chown root:root /var/run/vsftpd/empty
chmod 555 /var/run/vsftpd/empty

# Create FTP user with password from environment
echo "${FTP_USER}:${FTP_PASS}" | chpasswd
echo "FTP user ${FTP_USER} configured"

# Set up FTP directory permissions
chown -R ${FTP_USER}:${FTP_USER} /var/ftp
chmod -R 755 /var/ftp

echo "Starting vsftpd server."
exec /usr/sbin/vsftpd /etc/vsftpd.conf
