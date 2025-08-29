FROM alpine:latest

# Install MariaDB
RUN apk update && apk upgrade \
    && apk add --no-cache \
        mariadb \
        mariadb-client \
    && rm -rf /var/cache/apk/*

# Data directory
RUN mysql_install_db --user=mysql --datadir=/var/lib/mysql

# Copy config script
COPY ./conf/mdb_conf.sh /mdb_conf.sh
RUN chmod +x /mdb_conf.sh

# Expose port
EXPOSE 3306

# Entry point
ENTRYPOINT ["./mdb_conf.sh"]
