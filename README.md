# inception
You mustn't be afraid to dream a little bigger

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
│ OS      │ OS      │ OS              │      (Docker Engine)                │
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
     │                      docker rm                           │
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
| Development | 2-4 cores | 4-8 GB | 20-40 GB | Debian |
| Testing | 4-8 cores | 8-16 GB | 40-80 GB | Debian |
| Production-like | 8+ cores | 16+ GB | 100+ GB | Debian |

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
│                        Docker Host (VM)                             │
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
│  │  - inception_network (bridge)                               │    │
│  │  - Service discovery and communication                      │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Docker Volumes                           │    │
│  │  - wordpress_data: /var/www/html                            │    │
│  │  - mariadb_data: /var/lib/mysql                             │    │
│  │  - redis_data: /data                                        │    │
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
│                     (172.20.0.0/16)                         │
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
- Linux distribution (Debian recommended)
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

### Resources

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Container Security Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [CNCF Landscape](https://landscape.cncf.io/)

---

*Last updated: $(date +"%Y-%m-%d")*

**Project Status**: ✅ Production Ready | 🔒 Security Audited | 📊 Performance Optimized
