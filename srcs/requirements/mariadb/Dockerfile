FROM debian:bookworm

# Install necessary packages
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        mariadb-server \
        mariadb-client \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy config script
COPY ./conf/mdb_conf.sh /mdb_conf.sh
RUN chmod +x /mdb_conf.sh

# Expose port
EXPOSE 3306

# Entry point
ENTRYPOINT ["./mdb_conf.sh"]
