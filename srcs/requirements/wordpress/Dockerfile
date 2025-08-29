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
        curl \
        bash \
        mariadb-client \
        netcat-openbsd

# Create symlinks for PHP commands (Alpine uses php82)
RUN ln -sf /usr/bin/php82 /usr/bin/php \
    && ln -sf /usr/sbin/php-fpm82 /usr/sbin/php-fpm

# Make script executable
COPY /conf/wp_conf.sh /
RUN chmod +x wp_conf.sh

# Expose PHP-FPM port
EXPOSE 9000

ENTRYPOINT ["./wp_conf.sh"]
