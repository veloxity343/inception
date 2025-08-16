FROM debian:bullseye

# Install PHP-FPM and WordPress dependencies
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        curl \
        php \
        php7.4-fpm \
        php7.4-mysql \
        php7.4-curl \
        php7.4-gd \
        php7.4-intl \
        php7.4-mbstring \
        php7.4-xml \
        php7.4-zip \
        mariadb-client \
        wget \
        vim \
        zsh \
        git \
        netcat \
        mycli \
    && rm -rf /var/lib/apt/lists/*

# Copy WordPress configuration script
COPY /conf/wp_conf.sh /

# Make script executable
RUN chmod +x wp_conf.sh

# Expose PHP-FPM port
EXPOSE 9000

ENTRYPOINT ["./wp_conf.sh"]
