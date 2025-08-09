#!/bin/bash
set -e

echo "Starting NGINX configuration."

# Setup zsh for debug
if [ "${DEBUG_MODE:-false}" = "true" ]; then
	echo "DEBUG_MODE enabled - setting up zsh..."
	chsh -s $(which zsh) 2>/dev/null || true
	wget -q https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O /tmp/install.sh 2>/dev/null || true
	[ -f /tmp/install.sh ] && sh /tmp/install.sh --unattended 2>/dev/null || true
	echo "Zsh setup complete"
fi

# Generate self-signed SSL certificate if it doesn't exist
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Generating self-signed SSL certificate."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=MY/ST=KL/L=KualaLumpur/O=42KL/OU=student/CN=${DOMAIN_NAME}"
    
    # Set proper permissions
    chmod 600 /etc/nginx/ssl/nginx.key
    chmod 644 /etc/nginx/ssl/nginx.crt
    
    echo "SSL certificate generated successfully"
else
    echo "SSL certificate already exists"
fi

# Test NGINX config
echo "Testing NGINX configuration..."
nginx -t

# Start NGINX in foreground
echo "Starting NGINX server."
exec nginx -g "daemon off;"
