FROM debian:bookworm

# Install vsftpd and dependencies
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        vsftpd \
        openssl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

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
