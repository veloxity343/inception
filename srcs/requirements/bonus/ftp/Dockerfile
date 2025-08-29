FROM alpine:latest

# Install vsftpd and dependencies
RUN apk update && apk upgrade \
    && apk add --no-cache \
        vsftpd \
        openssl \
        bash \
    && rm -rf /var/cache/apk/*

# Create FTP directory structure
RUN mkdir -p /var/ftp/wordpress \
    && mkdir -p /var/log/vsftpd \
    && mkdir -p /etc/vsftpd

# Secure chroot dir for vsftpd
RUN mkdir -p /var/run/vsftpd/empty \
    && chown root:root /var/run/vsftpd/empty \
    && chmod 555 /var/run/vsftpd/empty

# Copy FTP configuration
COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/ftp-setup.sh /ftp-setup.sh

# Make setup script executable
RUN chmod +x /ftp-setup.sh

# Create FTP user directory
RUN mkdir -p /home/ftpuser \
    && useradd -d /home/ftpuser -s /bin/bash ftpuser

# Set proper permissions
RUN chown -R ftpuser:ftpuser /var/ftp \
    && chmod 755 /var/ftp

# Expose FTP ports
EXPOSE 21 20000-20010

# Run setup and start FTP server
ENTRYPOINT ["./ftp-setup.sh"]
