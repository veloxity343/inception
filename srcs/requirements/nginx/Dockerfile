FROM alpine:latest

RUN apk update && apk upgrade \
    && apk add --no-cache \
        nginx \
        openssl \
        bash \
    && rm -rf /var/cache/apk/*

# Create SSL directory
RUN mkdir -p /etc/nginx/ssl

# Create WordPress directory with proper permissions
RUN mkdir -p /var/www/wordpress \
    && adduser -D -g 'www' www \
    && chown -R www:www /var/www/wordpress

# Copy configuration files
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/auto.sh /auto.sh

RUN chmod +x /auto.sh

EXPOSE 443

ENTRYPOINT ["./auto.sh"]
