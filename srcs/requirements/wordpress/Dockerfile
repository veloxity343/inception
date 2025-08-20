FROM debian:bookworm

# Install PHP-FPM and WordPress dependencies
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        curl \
        php8.2 \
        php8.2-fpm \
        php8.2-mysql \
        php8.2-curl \
        php8.2-gd \
        php8.2-intl \
        php8.2-mbstring \
        php8.2-xml \
        php8.2-zip \
        mariadb-client \
        netcat-openbsd \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy WordPress configuration script
COPY /conf/wp_conf.sh /

# Make script executable
RUN chmod +x wp_conf.sh

# Expose PHP-FPM port
EXPOSE 9000

ENTRYPOINT ["./wp_conf.sh"]
