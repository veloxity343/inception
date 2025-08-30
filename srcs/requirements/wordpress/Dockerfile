FROM alpine:latest

RUN apk add --no-cache \
        php83-fpm \
        php83-mysqli \
        php83-curl \
        php83-gd \
        php83-mbstring \
        php83-xml \
        php83-zip \
        php83-phar \
        php83-pecl-redis \
        curl \
        bash \
        mariadb-client \
        netcat-openbsd

# Create symlinks for PHP commands
RUN ln -sf /usr/bin/php83 /usr/bin/php \
    && ln -sf /usr/sbin/php-fpm83 /usr/sbin/php-fpm

# Create WordPress directory and www user
RUN mkdir -p /var/www/wordpress \
    && adduser -D -g 'www' www \
    && chown -R www:www /var/www/wordpress

# Override PHP memory limit
RUN mkdir -p /etc/php83/conf.d \
    && echo "memory_limit = 512M" > /etc/php83/conf.d/99-custom.ini

# Make script executable
COPY ./tools/wp-setup.sh /
COPY ./conf/wp-config.php /usr/local/share/wp-config.php
RUN chmod +x wp-setup.sh

# Expose PHP-FPM port
EXPOSE 9000

ENTRYPOINT ["./wp-setup.sh"]
