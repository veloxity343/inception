FROM alpine:latest

# Install MariaDB
RUN apk update && apk upgrade \
    && apk add --no-cache \
        mariadb \
        mariadb-client \
    && rm -rf /var/cache/apk/*

# Copy entrypoint script
COPY ./conf/mdb_conf.sh /mdb_conf.sh
RUN chmod +x /mdb_conf.sh

# Expose port
EXPOSE 3306

# Use absolute path for entrypoint
ENTRYPOINT ["/mdb_conf.sh"]
