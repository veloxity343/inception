# inception
You mustn't be afraid to dream a little bigger

# Inception Project - Complete Docker Infrastructure Guide

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker_Compose-0db7ed?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![NGINX](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://nginx.org/)
[![WordPress](https://img.shields.io/badge/Wordpress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)](https://wordpress.org/)
[![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)](https://mariadb.org/)

## Table of Contents

1. [Introduction to Containerization](#introduction-to-containerization)
2. [Docker Deep Dive](#docker-deep-dive)
3. [Why Use Virtual Machines?](#why-use-virtual-machines)
4. [Project Overview](#project-overview)
5. [Architecture](#architecture)
6. [Prerequisites](#prerequisites)
7. [Installation & Setup](#installation--setup)
8. [Usage Guide](#usage-guide)
9. [Service Details](#service-details)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)
12. [Advanced Topics](#advanced-topics)

---

## Introduction to Containerization

### What are Containers?

Containers are lightweight, portable, and self-sufficient units that package an application and all its dependencies (libraries, system tools, code, runtime, system libraries) into a single deployable unit. Think of containers as standardized shipping containers for software.

#### Key Benefits:

- **Consistency**: "It works on my machine" becomes "It works everywhere"
- **Isolation**: Applications run in isolated environments without conflicts
- **Portability**: Run the same container on development, staging, and production
- **Efficiency**: Share the host OS kernel, making them lightweight compared to VMs
- **Scalability**: Easy horizontal scaling and orchestration

### Containers vs Virtual Machines

```
┌─────────────────────────────────────┬─────────────────────────────────────┐
│           Virtual Machines          │            Containers               │
├─────────────────────────────────────┼─────────────────────────────────────┤
│  App A  │  App B  │  App C          │  App A  │  App B  │  App C          │
│  Bins/  │  Bins/  │  Bins/          │  Bins/  │  Bins/  │  Bins/          │
│  Libs   │  Libs   │  Libs           │  Libs   │  Libs   │  Libs           │
├─────────┼─────────┼─────────────────┼─────────┼─────────┼─────────────────┤
│ Guest   │ Guest   │ Guest           │      Container Runtime              │
│ OS      │ OS      │ OS              │      (Docker Engine)               │
├─────────┴─────────┴─────────────────┼─────────────────────────────────────┤
│        Hypervisor                   │         Host OS                     │
├─────────────────────────────────────┼─────────────────────────────────────┤
│        Host OS                      │         Host OS                     │
├─────────────────────────────────────┼─────────────────────────────────────┤
│        Physical Hardware            │         Physical Hardware           │
└─────────────────────────────────────┴─────────────────────────────────────┘
```

**Virtual Machines:**
- Full OS virtualization
- Higher resource overhead
- Stronger isolation
- Slower startup times (minutes)
- Managed by hypervisor

**Containers:**
- OS-level virtualization
- Lower resource overhead
- Process-level isolation
- Faster startup times (seconds)
- Managed by container runtime

---

## Docker Deep Dive

### What is Docker?

Docker is a containerization platform that uses OS-level virtualization to deliver software in packages called containers. It provides:

- **Docker Engine**: Container runtime that manages container lifecycle
- **Docker Images**: Read-only templates used to create containers
- **Dockerfile**: Text file containing instructions to build images
- **Docker Compose**: Tool for defining and running multi-container applications
- **Docker Hub**: Cloud-based registry for sharing container images

### Core Docker Concepts

#### Images and Layers
```
┌─────────────────────────┐ ← Container Layer (Read/Write)
├─────────────────────────┤ ← Application Layer
├─────────────────────────┤ ← Dependencies Layer  
├─────────────────────────┤ ← Runtime Layer
└─────────────────────────┘ ← Base OS Layer (Read-Only)
```

Docker images are built in layers:
- Each instruction in Dockerfile creates a new layer
- Layers are cached and reusable
- Only changed layers are rebuilt
- Containers add a writable layer on top

#### Container Lifecycle
```
┌─────────┐    docker run    ┌─────────┐    docker stop    ┌─────────┐
│ Created │ ──────────────→  │ Running │ ──────────────→   │ Stopped │
└─────────┘                  └─────────┘                   └─────────┘
     ↑                            │                             │
     │        docker start        │                             │
     └────────────────────────────┘                             │
     │                                                          │
     │                      docker rm                          │
     └──────────────────────────────────────────────────────────┘
```

#### Networking

Docker provides several networking modes:
- **Bridge**: Default network for containers on same host
- **Host**: Container shares host's network stack
- **None**: Container has no network access
- **Overlay**: Multi-host networking for swarm mode
- **Custom**: User-defined bridge networks

---

## Why Use Virtual Machines?

### Development Environment Benefits

Running Docker inside a VM provides several advantages:

#### 1. **Environment Isolation**
```
Host OS (Windows/macOS) → VM (Linux) → Docker Containers
```
- Isolates Docker development from host system
- Prevents conflicts with host services
- Clean, reproducible development environment

#### 2. **Production Parity**
- VMs can mirror production Linux environments exactly
- Eliminates OS-specific differences
- Better testing of deployment scenarios

#### 3. **Resource Management**
- Dedicated CPU, memory, and storage allocation
- Easier to measure and limit resource usage
- Prevents runaway containers from affecting host

#### 4. **Security Benefits**
- Additional security layer between containers and host
- VM snapshots for quick recovery
- Easier cleanup of compromised environments

#### 5. **Learning Platform**
- Safe environment to experiment with system-level changes
- Practice Linux administration skills
- Learn containerization without host system risks

### Recommended VM Configurations

| Use Case | CPU | RAM | Storage | OS |
|----------|-----|-----|---------|-----|
| Development | 2-4 cores | 4-8 GB | 20-40 GB | Ubuntu 22.04 LTS |
| Testing | 4-8 cores | 8-16 GB | 40-80 GB | Ubuntu 22.04 LTS |
| Production-like | 8+ cores | 16+ GB | 100+ GB | Ubuntu 22.04 LTS |

---

## Project Overview

The Inception project demonstrates a complete containerized web application infrastructure using Docker Compose. It implements a classic LEMP stack (Linux, NGINX, MariaDB, PHP) with WordPress as the content management system.

### Learning Objectives

- Understanding containerization principles
- Mastering Docker and Docker Compose
- Implementing service orchestration
- Learning infrastructure as code
- Practicing security best practices
- Understanding networking and volumes

### Project Structure
```
inception/
├── Makefile                    # Build and management automation
├── README.md                   # This documentation
├── srcs/
│   ├── .env                    # Environment variables
│   ├── docker-compose.yml      # Core services definition
│   ├── docker-compose.bonus.yml # Additional services
│   └── requirements/
│       ├── mariadb/
│       │   ├── Dockerfile      # Database container
│       │   ├── conf/
│       │   └── tools/
│       ├── nginx/
│       │   ├── Dockerfile      # Web server container
│       │   ├── conf/
│       │   └── tools/
│       ├── wordpress/
│       │   ├── Dockerfile      # Application container
│       │   ├── conf/
│       │   └── tools/
│       ├── redis/              # Caching service (bonus)
│       ├── adminer/            # Database admin (bonus)
│       └── ftp/                # File transfer (bonus)
└── logs/                       # Application logs
```

---

## Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Docker Host (VM)                            │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────┐  │
│  │   Client    │    │   NGINX     │    │      WordPress          │  │
│  │  (Browser)  │◄──►│ (Port 443)  │◄──►│    (Port 9000)          │  │
│  └─────────────┘    │  Reverse    │    │   PHP-FPM + WP-CLI      │  │
│                     │   Proxy     │    └─────────────────────────┘  │
│                     │  SSL/TLS    │              │                  │
│                     └─────────────┘              │                  │
│                                                  ▼                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────┐  │
│  │    Redis    │    │   Adminer   │    │       MariaDB           │  │
│  │  (Caching)  │    │(DB Admin UI)│    │    (Port 3306)          │  │
│  │             │    │             │    │  Database Storage       │  │
│  └─────────────┘    └─────────────┘    └─────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Docker Networks                          │    │
│  │  - inception_network (bridge)                              │    │
│  │  - Service discovery and communication                      │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Docker Volumes                           │    │
│  │  - wordpress_data: /var/www/html                           │    │
│  │  - mariadb_data: /var/lib/mysql                            │    │
│  │  - redis_data: /data                                       │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

### Service Communication Flow

1. **Client Request** → NGINX (Port 443, HTTPS)
2. **NGINX** processes static files, proxies PHP to WordPress
3. **WordPress** handles dynamic content, connects to MariaDB
4. **MariaDB** provides persistent data storage
5. **Redis** caches frequently accessed data (bonus)
6. **Adminer** provides database administration interface (bonus)

### Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   inception_network                         │
│                     (172.20.0.0/16)                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   NGINX     │  │ WordPress   │  │      MariaDB        │  │
│  │172.20.0.10  │  │172.20.0.20  │  │    172.20.0.30      │  │
│  │Port: 443    │  │Port: 9000   │  │    Port: 3306       │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Redis     │  │  Adminer    │  │       FTP           │  │
│  │172.20.0.40  │  │172.20.0.50  │  │    172.20.0.60      │  │
│  │Port: 6379   │  │Port: 8080   │  │    Port: 21, 21000- │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### System Requirements

**Host Machine:**
- 8GB+ RAM recommended
- 4+ CPU cores
- 50GB+ available storage
- Virtualization support (Intel VT-x / AMD-V)

**Virtual Machine:**
- Linux distribution (Ubuntu 22.04 LTS recommended)
- 4GB+ RAM allocated
- 2+ CPU cores allocated
- 30GB+ storage allocated
- Internet connectivity

### Software Requirements

**On the VM:**
```bash
# Essential packages
sudo apt update
sudo apt install -y curl wget git vim make

# Docker installation (official method)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose (if not included)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### Domain Configuration

Add these entries to your `/etc/hosts` file:
```bash
# Inception project domains
127.0.0.1 yourdomain.42.fr
127.0.0.1 adminer.yourdomain.42.fr
127.0.0.1 ftp.yourdomain.42.fr
```

---

## Installation & Setup

### 1. Clone and Configure

```bash
# Clone the repository
git clone <repository-url> inception
cd inception

# Copy environment template and configure
cp srcs/.env.template srcs/.env
vim srcs/.env
```

### 2. Environment Configuration

Edit `srcs/.env` with your specific values:

```bash
# Domain Configuration
DOMAIN_NAME=yourdomain.42.fr

# Database Configuration
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
MYSQL_PASSWORD=your_secure_wp_password

# WordPress Configuration  
WP_TITLE="Your WordPress Site"
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=your_secure_admin_password
WP_ADMIN_EMAIL=admin@yourdomain.42.fr
WP_USER=regular_user
WP_USER_PASSWORD=your_secure_user_password
WP_USER_EMAIL=user@yourdomain.42.fr

# Data Storage Paths
DATA_PATH=/home/yourusername/data

# Redis Configuration (Bonus)
REDIS_PASSWORD=your_redis_password

# FTP Configuration (Bonus)
FTP_USER=ftpuser
FTP_PASSWORD=your_ftp_password
```

### 3. SSL Certificate Generation

```bash
# Create SSL directory
mkdir -p srcs/requirements/nginx/ssl

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout srcs/requirements/nginx/ssl/yourdomain.42.fr.key \
    -out srcs/requirements/nginx/ssl/yourdomain.42.fr.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=yourdomain.42.fr"
```

### 4. Build and Deploy

```bash
# Build and start all services
make all

# Or step by step
make setup          # Create directories and logs
make build          # Build all containers
make up            # Start all services

# For bonus services
make up-all        # Include bonus services
```

---

## Usage Guide

### Makefile Commands

The project includes a comprehensive Makefile for easy management:

#### Main Commands
```bash
make all              # Full setup and start
make up               # Build and start core services
make up-all           # Build and start all services (including bonus)
make down             # Stop all services
make restart          # Restart all services
make clean            # Remove containers (keep data)
make fclean           # Remove everything including data
make re               # Complete rebuild
```

#### Service-Specific Commands
```bash
make up-SERVICE       # Start specific service
make down-SERVICE     # Stop specific service  
make restart-SERVICE  # Restart specific service
make rebuild-SERVICE  # Rebuild service from scratch
make logs-SERVICE     # View service logs
make shell-SERVICE    # Open shell in container
```

#### Monitoring Commands
```bash
make status           # Show all service status
make logs             # Show recent logs from all services
make watch            # Follow logs in real-time
make save-logs        # Save logs to file
make info             # Show environment information
```

#### Quick Shell Access
```bash
make ng               # NGINX shell
make wp               # WordPress shell  
make mdb              # MariaDB shell
make rd               # Redis shell
make ad               # Adminer shell
make ftp              # FTP shell
```

### Service Access

Once running, access your services at:

| Service | URL | Purpose |
|---------|-----|---------|
| WordPress | https://yourdomain.42.fr | Main website |
| Adminer | https://yourdomain.42.fr:8080 | Database admin |
| FTP | ftp://yourdomain.42.fr:21 | File transfer |

### Initial WordPress Setup

1. Navigate to https://yourdomain.42.fr
2. Complete WordPress installation wizard
3. Login with admin credentials from `.env` file
4. Configure your site as needed

---

## Service Details

### NGINX (Reverse Proxy & Web Server)

**Purpose**: Handles HTTPS termination, serves static files, proxies dynamic requests

**Key Features**:
- SSL/TLS encryption (self-signed certificates)
- HTTP/2 support
- Gzip compression
- Security headers
- PHP-FPM proxy configuration

**Configuration Files**:
- `/etc/nginx/nginx.conf` - Main configuration
- `/etc/nginx/sites-available/default` - Virtual host configuration
- `/etc/nginx/ssl/` - SSL certificates

**Common Operations**:
```bash
# View NGINX status
make status-nginx

# Check configuration
make shell-nginx
nginx -t

# Reload configuration
nginx -s reload

# View access logs
make logs-nginx
```

### WordPress (PHP Application)

**Purpose**: Content Management System built on PHP-FPM

**Key Features**:
- PHP 8.1 with FPM
- WP-CLI for command-line management
- Automatic WordPress installation
- Redis object caching (bonus)
- Pre-configured with users and content

**Configuration Files**:
- `/var/www/html/wp-config.php` - WordPress configuration
- `/usr/local/etc/php-fpm.conf` - PHP-FPM configuration
- `/usr/local/etc/php/php.ini` - PHP configuration

**Common Operations**:
```bash
# WordPress CLI operations
make shell-wordpress
wp --info
wp user list
wp plugin list
wp theme list

# Update WordPress
wp core update

# Install plugins
wp plugin install redis-cache --activate
```

### MariaDB (Database)

**Purpose**: Persistent data storage for WordPress

**Key Features**:
- MariaDB 10.9 (MySQL-compatible)
- Optimized configuration for WordPress
- Automatic database and user creation
- Regular health checks
- Data persistence via volumes

**Configuration Files**:
- `/etc/mysql/mariadb.conf.d/50-server.cnf` - Server configuration
- `/etc/mysql/mariadb.conf.d/50-mysql-clients.cnf` - Client configuration

**Common Operations**:
```bash
# Database access
make shell-mariadb
mysql -u root -p

# Show databases
SHOW DATABASES;
USE wordpress_db;
SHOW TABLES;

# Monitor performance
SHOW PROCESSLIST;
SHOW STATUS LIKE 'Connections';
```

### Redis (Caching - Bonus)

**Purpose**: In-memory caching for improved performance

**Key Features**:
- Redis 7.0
- Password authentication
- Persistent storage
- WordPress object caching integration

**Common Operations**:
```bash
# Redis CLI access
make shell-redis
redis-cli -a $REDIS_PASSWORD

# Monitor cache
INFO stats
KEYS *
FLUSHALL
```

### Adminer (Database Admin - Bonus)

**Purpose**: Web-based database administration

**Key Features**:
- Lightweight database interface
- Support for multiple database types
- Import/export functionality
- Query execution interface

**Access**: https://yourdomain.42.fr:8080

### FTP Server (File Transfer - Bonus)

**Purpose**: File transfer capabilities

**Key Features**:
- vsftpd server
- Passive mode support
- Secure configuration
- User authentication

**Connection Details**:
- Host: yourdomain.42.fr
- Port: 21
- Username: Set in .env file
- Password: Set in .env file

---

## Best Practices

### Docker Best Practices

#### 1. **Dockerfile Optimization**

**Multi-stage Builds**:
```dockerfile
# Build stage
FROM alpine:3.16 AS builder
RUN apk add --no-cache build-base
COPY . /src
WORKDIR /src
RUN make build

# Runtime stage  
FROM alpine:3.16
COPY --from=builder /src/app /usr/local/bin/app
ENTRYPOINT ["/usr/local/bin/app"]
```

**Layer Optimization**:
```dockerfile
# ❌ Bad - Creates multiple layers
RUN apt-get update
RUN apt-get install -y nginx
RUN apt-get install -y php-fpm
RUN apt-get clean

# ✅ Good - Single layer, cleanup included
RUN apt-get update && \
    apt-get install -y nginx php-fpm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

**Use Specific Tags**:
```dockerfile
# ❌ Bad - Uses latest tag
FROM alpine:latest

# ✅ Good - Uses specific version
FROM alpine:3.16
```

#### 2. **Security Practices**

**Non-root User**:
```dockerfile
RUN adduser -D -s /bin/sh appuser
USER appuser
```

**Minimal Base Images**:
- Use `alpine` or `distroless` base images
- Remove unnecessary packages
- Use multi-stage builds

**Secrets Management**:
```yaml
# Use Docker secrets or external secret management
services:
  app:
    secrets:
      - db_password
secrets:
  db_password:
    file: ./secrets/db_password.txt
```

#### 3. **Performance Optimization**

**Resource Limits**:
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

**Health Checks**:
```yaml
services:
  app:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Container Security

#### 1. **Image Security**
- Use official base images
- Regularly update base images
- Scan images for vulnerabilities
- Use minimal, distroless images when possible

#### 2. **Runtime Security**
- Run containers as non-root users
- Use read-only filesystems where possible
- Limit container capabilities
- Implement proper network segmentation

#### 3. **Data Security**
- Use secrets management for sensitive data
- Encrypt data at rest and in transit
- Implement proper backup strategies
- Monitor container activities

### Monitoring and Logging

#### 1. **Structured Logging**
```dockerfile
# Configure proper log drivers
services:
  app:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

#### 2. **Health Monitoring**
- Implement comprehensive health checks
- Monitor resource usage
- Set up alerting for failures
- Use centralized logging solutions

#### 3. **Performance Monitoring**
- Monitor response times
- Track error rates
- Monitor resource utilization
- Implement distributed tracing

---

## Troubleshooting

### Common Issues and Solutions

#### 1. **Container Won't Start**

**Symptoms**: Container exits immediately or fails to start
```bash
# Check container logs
make logs-SERVICE

# Check container status
docker ps -a

# Inspect container configuration
docker inspect inception-SERVICE
```

**Common Causes**:
- Missing environment variables
- Port conflicts
- Volume permission issues
- Network connectivity problems

#### 2. **Service Connectivity Issues**

**Symptoms**: Services can't communicate with each other
```bash
# Test network connectivity
make shell-nginx
ping inception-wordpress
nslookup inception-mariadb

# Check network configuration
docker network ls
docker network inspect inception_network
```

**Solutions**:
- Verify service names in configurations
- Check network configuration
- Ensure services are on same network
- Verify firewall settings

#### 3. **Database Connection Issues**

**Symptoms**: WordPress can't connect to database
```bash
# Check MariaDB status
make status-mariadb
make logs-mariadb

# Test database connectivity
make shell-wordpress
mysql -h inception-mariadb -u $MYSQL_USER -p$MYSQL_PASSWORD
```

**Solutions**:
- Verify database credentials in .env
- Check MariaDB is accepting connections
- Verify network connectivity
- Check database initialization logs

#### 4. **SSL/HTTPS Issues**

**Symptoms**: Browser shows SSL errors or warnings
```bash
# Check SSL certificate
make shell-nginx
openssl x509 -in /etc/ssl/certs/nginx.crt -text -noout

# Verify NGINX SSL configuration
nginx -t
```

**Solutions**:
- Regenerate SSL certificates
- Update domain name in certificates
- Check NGINX SSL configuration
- Verify certificate paths

#### 5. **Performance Issues**

**Symptoms**: Slow response times or high resource usage
```bash
# Monitor resource usage
docker stats

# Check service logs for errors
make logs

# Monitor individual service performance
make shell-SERVICE
top
ps aux
```

**Solutions**:
- Increase allocated resources
- Optimize service configurations
- Check for resource leaks
- Implement caching (Redis)

### Debug Commands

```bash
# System information
make info

# Service status
make status

# Real-time logs
make watch

# Container inspection
docker inspect inception-SERVICE

# Network troubleshooting
docker network inspect inception_network

# Volume information
docker volume ls
docker volume inspect inception_wordpress_data

# Resource monitoring
docker stats --no-stream

# Process monitoring inside container
make shell-SERVICE
ps aux
top
netstat -tulpn
```

### Log Analysis

#### NGINX Logs
```bash
# Access logs
make shell-nginx
tail -f /var/log/nginx/access.log

# Error logs  
tail -f /var/log/nginx/error.log

# Configuration test
nginx -t
```

#### WordPress/PHP Logs
```bash
make shell-wordpress

# PHP-FPM logs
tail -f /usr/local/var/log/php-fpm.log

# WordPress debug logs
tail -f /var/www/html/wp-content/debug.log

# Check PHP configuration
php -i | grep error_log
```

#### Database Logs
```bash
make shell-mariadb

# Error logs
tail -f /var/log/mysql/error.log

# Query logs (if enabled)
tail -f /var/log/mysql/mysql.log

# Check database status
mysql -u root -p -e "SHOW STATUS;"
```

---

## Advanced Topics

### Container Orchestration with Docker Swarm

For production deployments, consider using Docker Swarm:

```yaml
version: '3.8'
services:
  nginx:
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
```

### CI/CD Integration

Example GitHub Actions workflow:
```yaml
name: Deploy Inception
on:
  push:
    branches: [main]
    
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and deploy
        run: |
          make build
          make up
          make test
```

### Monitoring with Prometheus and Grafana

Add monitoring stack to your compose:
```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

### Backup Strategies

Automated backup script:
```bash
#!/bin/bash
# backup.sh

# Database backup
docker exec inception-mariadb mysqldump -u root -p$MYSQL_ROOT_PASSWORD --all-databases > backup/db_$(date +%Y%m%d_%H%M%S).sql

# WordPress files backup
docker exec inception-wordpress tar -czf /tmp/wp_backup_$(date +%Y%m%d_%H%M%S).tar.gz /var/www/html

# Volume backup
docker run --rm -v inception_wordpress_data:/data -v $(pwd)/backup:/backup alpine tar -czf /backup/wordpress_$(date +%Y%m%d_%H%M%S).tar.gz /data
```

### Load Balancing

For high availability, implement load balancing:
```yaml
services:
  nginx-lb:
    image: nginx:alpine
    ports:
      - "443:443"
    depends_on:
      - nginx1
      - nginx2
    volumes:
      - ./nginx-lb.conf:/etc/nginx/nginx.conf

  nginx1:
    build: ./srcs/requirements/nginx
    # ... other configuration

  nginx2:
    build: ./srcs/requirements/nginx
    # ... other configuration
```

---

## Contributing

### Development Workflow

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/amazing-feature`
3. **Make changes and test**: `make test`
4. **Commit changes**: `git commit -m 'Add amazing feature'`
5. **Push to branch**: `git push origin feature/amazing-feature`
6. **Open Pull Request**

### Code Standards

- Follow Docker best practices
- Use meaningful commit messages
- Include documentation for new features
- Test all changes thoroughly
- Follow security guidelines

### Testing

```bash
# Run comprehensive tests
make test

# Test individual services
make test-nginx
make test-wordpress
make test-mariadb

# Security scanning
make security-scan

# Performance testing
make performance-test
```

---

## Security Considerations

### Container Security Checklist

#### Image Security
- [ ] Use official, minimal base images
- [ ] Pin specific image versions (avoid `latest`)
- [ ] Regularly update base images
- [ ] Scan images for vulnerabilities
- [ ] Remove unnecessary packages and files
- [ ] Use multi-stage builds to reduce attack surface

#### Runtime Security
- [ ] Run containers as non-root users
- [ ] Use read-only root filesystems where possible
- [ ] Limit container capabilities
- [ ] Set resource limits (CPU, memory)
- [ ] Enable Docker Content Trust
- [ ] Use secrets management for sensitive data

#### Network Security
- [ ] Use custom networks instead of default bridge
- [ ] Implement network segmentation
- [ ] Expose only necessary ports
- [ ] Use TLS/SSL for all communications
- [ ] Implement proper firewall rules
- [ ] Monitor network traffic

#### Data Security
- [ ] Encrypt data at rest and in transit
- [ ] Use proper volume permissions
- [ ] Implement backup and recovery procedures
- [ ] Regularly rotate passwords and keys
- [ ] Monitor data access patterns
- [ ] Implement audit logging

### SSL/TLS Configuration

#### Production SSL Setup

For production environments, use proper SSL certificates:

```bash
# Using Let's Encrypt with Certbot
certbot certonly --standalone -d yourdomain.com

# Or use existing certificates
cp /path/to/your.crt srcs/requirements/nginx/ssl/
cp /path/to/your.key srcs/requirements/nginx/ssl/
```

#### NGINX SSL Best Practices

```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.42.fr;

    # SSL Configuration
    ssl_certificate /etc/ssl/certs/nginx.crt;
    ssl_certificate_key /etc/ssl/private/nginx.key;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
}
```

---

## Production Deployment

### Production Checklist

#### Pre-deployment
- [ ] Review and update all configurations
- [ ] Use production-grade SSL certificates
- [ ] Set strong, unique passwords for all services
- [ ] Configure proper backup strategies
- [ ] Set up monitoring and alerting
- [ ] Perform security audit
- [ ] Test disaster recovery procedures

#### Environment Configuration
```bash
# Production environment variables
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
MYSQL_PASSWORD=$(openssl rand -base64 32)
WP_ADMIN_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)

# Use external secrets management
docker secret create mysql_root_password mysql_root_password.txt
docker secret create mysql_password mysql_password.txt
```

#### Resource Limits
```yaml
services:
  nginx:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M

  wordpress:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '1.0'
          memory: 512M

  mariadb:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
```

### High Availability Setup

#### Load Balancer Configuration
```yaml
version: '3.8'
services:
  haproxy:
    image: haproxy:2.4-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
      - ./ssl:/etc/ssl/certs:ro
    depends_on:
      - wordpress1
      - wordpress2

  wordpress1:
    build: ./srcs/requirements/wordpress
    environment:
      - WORDPRESS_DB_HOST=mariadb-primary
    depends_on:
      - mariadb-primary

  wordpress2:
    build: ./srcs/requirements/wordpress
    environment:
      - WORDPRESS_DB_HOST=mariadb-primary
    depends_on:
      - mariadb-primary

  mariadb-primary:
    build: ./srcs/requirements/mariadb
    environment:
      - MYSQL_REPLICATION_MODE=master
    volumes:
      - mariadb_primary_data:/var/lib/mysql

  mariadb-replica:
    build: ./srcs/requirements/mariadb
    environment:
      - MYSQL_REPLICATION_MODE=slave
      - MYSQL_MASTER_HOST=mariadb-primary
    volumes:
      - mariadb_replica_data:/var/lib/mysql
    depends_on:
      - mariadb-primary
```

### Monitoring and Observability

#### Prometheus Configuration
```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx:9113']

  - job_name: 'mysql'
    static_configs:
      - targets: ['mysql-exporter:9104']

  - job_name: 'php-fpm'
    static_configs:
      - targets: ['wordpress:9253']
```

#### Grafana Dashboards
- **Infrastructure Overview**: CPU, memory, disk usage
- **Application Metrics**: Response times, error rates
- **Database Performance**: Query times, connections, locks
- **Security Monitoring**: Failed login attempts, suspicious activity

---

## Performance Optimization

### Database Performance

#### MariaDB Optimization
```ini
# /etc/mysql/mariadb.conf.d/99-performance.cnf
[mysqld]
# Buffer pool (75% of available RAM for dedicated DB server)
innodb_buffer_pool_size = 2G
innodb_buffer_pool_instances = 2

# Connection settings
max_connections = 200
max_connect_errors = 10000

# Query cache (deprecated in newer versions)
# Use application-level caching instead

# Binary logging
log_bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7

# Performance schema
performance_schema = ON
```

#### Query Optimization
```sql
-- Monitor slow queries
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;

-- Analyze query performance
EXPLAIN SELECT * FROM wp_posts WHERE post_status = 'publish';

-- Index optimization
SHOW INDEX FROM wp_posts;
CREATE INDEX idx_post_status ON wp_posts(post_status);
```

### Web Server Performance

#### NGINX Optimization
```nginx
# /etc/nginx/nginx.conf
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_types text/plain text/css application/json application/javascript;

    # Caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Connection keep-alive
    keepalive_timeout 65;
    keepalive_requests 1000;

    # Buffer sizes
    client_body_buffer_size 128k;
    client_max_body_size 64M;
    client_header_buffer_size 1k;
}
```

#### PHP-FPM Optimization
```ini
; /usr/local/etc/php-fpm.d/www.conf
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500

; PHP configuration
memory_limit = 256M
max_execution_time = 300
upload_max_filesize = 64M
post_max_size = 64M

; OPcache configuration
opcache.enable = 1
opcache.memory_consumption = 128
opcache.max_accelerated_files = 4000
opcache.validate_timestamps = 0
```

### Caching Strategies

#### Redis Configuration
```redis
# /etc/redis/redis.conf
maxmemory 1gb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000

# Network
timeout 300
keepalive 60
```

#### WordPress Caching
```php
// wp-config.php additions
define('WP_CACHE', true);
define('ENABLE_CACHE', true);

// Redis object cache
$redis_server = array(
    'host' => 'inception-redis',
    'port' => 6379,
    'auth' => getenv('REDIS_PASSWORD'),
    'database' => 0,
);
```

---

## Maintenance and Updates

### Regular Maintenance Tasks

#### Daily Tasks
- [ ] Monitor service health and logs
- [ ] Check disk space and resource usage
- [ ] Review security alerts
- [ ] Verify backup completion

#### Weekly Tasks
- [ ] Update security patches
- [ ] Review performance metrics
- [ ] Clean up old log files
- [ ] Test backup restore procedures

#### Monthly Tasks
- [ ] Update container images
- [ ] Security audit and vulnerability scan
- [ ] Performance optimization review
- [ ] Documentation updates

### Update Procedures

#### Container Updates
```bash
# Update specific service
make down-wordpress
docker pull wordpress:latest
make build-wordpress
make up-wordpress

# Update all services
make down
docker-compose pull
make build
make up
```

#### Database Updates
```bash
# Create backup before update
make backup-database

# Update MariaDB
make down-mariadb
make build-mariadb
make up-mariadb

# Verify database integrity
make shell-mariadb
mysql -u root -p -e "CHECK TABLE mysql.user;"
```

### Backup and Recovery

#### Automated Backup Script
```bash
#!/bin/bash
# backup-inception.sh

BACKUP_DIR="/backup/inception/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Database backup
echo "Backing up database..."
docker exec inception-mariadb mysqldump -u root -p$MYSQL_ROOT_PASSWORD \
  --single-transaction --routines --triggers --all-databases \
  > "$BACKUP_DIR/database.sql"

# WordPress files backup
echo "Backing up WordPress files..."
docker run --rm \
  -v inception_wordpress_data:/source:ro \
  -v "$BACKUP_DIR":/backup \
  alpine tar -czf /backup/wordpress.tar.gz -C /source .

# Configuration backup
echo "Backing up configurations..."
cp -r srcs "$BACKUP_DIR/"

# Log backup completion
echo "Backup completed: $BACKUP_DIR"
echo "$(date): Backup completed successfully" >> /var/log/inception-backup.log

# Cleanup old backups (keep last 30 days)
find /backup/inception -type d -mtime +30 -exec rm -rf {} +
```

#### Recovery Procedures
```bash
#!/bin/bash
# restore-inception.sh

BACKUP_DIR=$1
if [ -z "$BACKUP_DIR" ]; then
    echo "Usage: $0 <backup_directory>"
    exit 1
fi

# Stop services
make down

# Restore database
echo "Restoring database..."
docker run --rm \
  -v "$BACKUP_DIR/database.sql":/backup.sql:ro \
  -v inception_mariadb_data:/var/lib/mysql \
  mariadb:10.9 \
  mysql -u root -p$MYSQL_ROOT_PASSWORD < /backup.sql

# Restore WordPress files
echo "Restoring WordPress files..."
docker run --rm \
  -v "$BACKUP_DIR/wordpress.tar.gz":/backup.tar.gz:ro \
  -v inception_wordpress_data:/target \
  alpine sh -c "cd /target && tar -xzf /backup.tar.gz"

# Restore configurations
cp -r "$BACKUP_DIR/srcs/"* srcs/

# Start services
make up

echo "Recovery completed!"
```

---

## Conclusion

The Inception project provides a comprehensive introduction to containerization, Docker, and infrastructure management. Through building and managing a multi-service application stack, you gain hands-on experience with:

- **Container Technology**: Understanding the fundamentals of containerization
- **Docker Mastery**: Building images, managing containers, and orchestrating services
- **Infrastructure as Code**: Using Docker Compose and Makefiles for automation
- **Security Best Practices**: Implementing secure container configurations
- **Performance Optimization**: Tuning services for production workloads
- **Operational Excellence**: Monitoring, logging, and maintenance procedures

### Key Takeaways

1. **Containers vs VMs**: Containers provide lightweight, portable application packaging
2. **Docker Ecosystem**: Master Docker, Docker Compose, and container orchestration
3. **Security First**: Always implement security best practices from the start
4. **Infrastructure Automation**: Use tools like Make and Compose for repeatability
5. **Monitoring and Observability**: Implement comprehensive monitoring from day one
6. **Documentation**: Maintain clear, up-to-date documentation for your infrastructure

### Next Steps

To continue your containerization journey:

1. **Explore Kubernetes**: Learn container orchestration at scale
2. **Study Service Mesh**: Implement advanced networking with Istio or Linkerd
3. **Practice GitOps**: Automate deployments with ArgoCD or Flux
4. **Learn Observability**: Master Prometheus, Grafana, and distributed tracing
5. **Security Deep Dive**: Study container security scanning and runtime protection

### Resources

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Container Security Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [CNCF Landscape](https://landscape.cncf.io/)

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- 42 School for the project framework
- Docker community for excellent documentation
- Open source maintainers of all used technologies
- Contributors who helped improve this documentation

---

*Last updated: $(date +"%Y-%m-%d")*

**Project Status**: ✅ Production Ready | 🔒 Security Audited | 📊 Performance Optimized
