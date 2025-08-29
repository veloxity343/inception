FROM alpine:latest

# Install MariaDB
RUN apk update && apk upgrade \
    && apk add --no-cache \
        mariadb \
        mariadb-client \
    && rm -rf /var/cache/apk/*

# MariaDB config
COPY ./conf/mdb.conf /etc/my.cnf.d/mdb.conf

# Setup script
COPY ./tools/mdb-setup.sh /usr/local/bin/mdb-setup.sh
RUN chmod +x /usr/local/bin/mdb-setup.sh

# Ensure runtime directories
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

# Persistent data
VOLUME ["/var/lib/mysql"]

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mdb-setup.sh"]
