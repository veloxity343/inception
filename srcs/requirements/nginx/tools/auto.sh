#!/bin/bash
set -e

echo "Starting NGINX configuration..."

# Generate self-signed SSL certificate
echo "Generating SSL certificate for domain: ${DOMAIN_NAME}"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=MY/ST=KL/L=KualaLumpur/O=42KL/OU=student/CN=${DOMAIN_NAME:-rcheong.42.fr}"
    
# Set proper permissions
chmod 600 /etc/nginx/ssl/nginx.key
chmod 644 /etc/nginx/ssl/nginx.crt

echo "SSL certificate generated successfully for ${DOMAIN_NAME}"

# Test NGINX config
echo "Testing NGINX configuration..."
nginx -t

# Start NGINX in foreground
echo "Starting NGINX server on port 443 (HTTPS)"
exec nginx -g "daemon off;"
