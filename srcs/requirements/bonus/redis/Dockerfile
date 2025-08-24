FROM debian:bookworm

# Install Redis
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        redis-server \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create Redis user and directories
RUN mkdir -p /var/lib/redis \
    && mkdir -p /var/log/redis \
    && mkdir -p /etc/redis \
    && chown -R redis:redis /var/lib/redis \
    && chown -R redis:redis /var/log/redis

# Copy Redis configuration
COPY conf/redis.conf /etc/redis/redis.conf

# Set proper permissions
RUN chown redis:redis /etc/redis/redis.conf \
    && chmod 640 /etc/redis/redis.conf

# Expose Redis port
EXPOSE 6379

# Switch to redis user
USER redis

# Start Redis server
CMD ["redis-server", "/etc/redis/redis.conf"]
