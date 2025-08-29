FROM alpine:latest

# Install PHP and dependencies
RUN apk update && apk upgrade \
    && apk add --no-cache \
        php83 \
        php83-mysqli \
        php83-session \
        php83-json \
        wget \
    && rm -rf /var/cache/apk/*

# Create symlink for PHP
RUN ln -sf /usr/bin/php83 /usr/bin/php

# Setup Adminer
RUN mkdir -p /var/www/html \
    && wget -O /var/www/html/index.php https://github.com/vrana/adminer/releases/download/v5.3.0/adminer-5.3.0.php

# Expose port 8080
EXPOSE 8080

# Start PHP server
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]
