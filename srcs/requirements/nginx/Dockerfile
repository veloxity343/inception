FROM debian:bookworm

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        nginx \
        openssl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create SSL directory
RUN mkdir -p /etc/nginx/ssl

# Create WordPress directory with proper permissions
RUN mkdir -p /var/www/wordpress \
    && chown -R www-data:www-data /var/www/wordpress

# Copy configuration files
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/auto.sh /auto.sh

RUN chmod +x /auto.sh

EXPOSE 443

ENTRYPOINT ["./auto.sh"]
