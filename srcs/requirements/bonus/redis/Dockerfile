FROM alpine:latest

# Install Redis
RUN apk update && apk upgrade \
    && apk add --no-cache \
        redis \
        bash \
    && rm -rf /var/cache/apk/*

# Create Redis user and directories (redis user exists in Alpine)
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
