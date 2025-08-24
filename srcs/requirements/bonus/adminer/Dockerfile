FROM debian:bookworm

# Install PHP and dependencies
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        php8.2 \
        php8.2-mysql \
        wget \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Setup Adminer
RUN mkdir -p /var/www/html \
    && wget -O /var/www/html/index.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

# Expose port 8080
EXPOSE 8080

# Start PHP server
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]
