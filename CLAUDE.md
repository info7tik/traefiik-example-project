# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**FShop** is a containerized multi-service application demonstrating Traefik as a reverse proxy and API gateway. It consists of:

- **Traefik** (v3.7.1): Reverse proxy handling routing, HTTPS/TLS termination, and certificate management
- **Spring Boot API** (Java 17): REST API served at `/api/*` paths
- **Apache Frontend** (httpd 2.4): Static HTML served at `/`

All services run in Docker containers orchestrated by Docker Compose with automatic service discovery via Traefik labels.

## Architecture & Key Design

### Service Discovery & Routing
- Traefik discovers services via Docker labels (`traefik.enable=true`, `traefik.http.routers.*`)
- Path-based routing: Traefik routes requests to `/api/*` → Spring Boot, `/` → Apache
- Middleware strips `/api` prefix before forwarding requests to Spring Boot (path becomes `/welcome`, not `/api/welcome`)

### HTTPS & TLS
- Automatic HTTP → HTTPS redirection via Traefik
- Let's Encrypt integration: Certificates auto-renewed in `letsencrypt/acme.json`
- Local development uses self-signed certificates from `certs/cert.pem` and `certs/key.pem`
- Dynamic TLS configuration loaded from `traefik-dynamic.yml`

### Networking
- All services on a single `frontend` bridge network for inter-container DNS resolution
- Traefik listens on ports 80 and 443; services are internal-only

## Directory Structure

```
api/
  └─ src/main/java/fr/fshop/
    ├── Application.java       # Spring Boot entry point
    └── WelcomeController.java # Single REST endpoint: GET /welcome
  └─ src/test/java/fr/fshop/
    └── WelcomeControllerTest.java # Unit tests
  └─ docker/
    └── fshop-api.dockerfile  # Multi-stage build (Maven → Java 21 JRE)
  └─ pom.xml                  # Maven dependencies

ui/
  └─ index.html               # Single HTML file; loads message from /api/welcome

docker-compose.yml            # Defines traefik, springboot, frontend services
traefik-dynamic.yml           # TLS certificate configuration
certs/                        # Self-signed certificates (local development)
letsencrypt/                  # Let's Encrypt certificate storage (auto-managed)
```

## Common Development Commands

### Docker Compose (Full Stack)

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f traefik
docker-compose logs -f springboot
docker-compose logs -f httpd

# Rebuild and restart (after code changes)
docker-compose up -d --build springboot
```

### API Development (Spring Boot)

```bash
cd api

# Build the application
mvn clean package

# Run tests
mvn test

# Run a single test
mvn test -Dtest=WelcomeControllerTest

# Run the application locally (without Docker)
# Sets server.port=8888 by default
mvn spring-boot:run

# Build the Docker image
docker build -f docker/fshop-api.dockerfile -t fshop-api .
```

### Testing the Application

```bash
# Test via HTTPS (ignore certificate warnings)
curl -k https://localhost/api/welcome

# Test frontend
curl -k https://localhost/

# Check API health
curl -k https://localhost/api/actuator/health
```

## Configuration Notes

### For Production
- Update `docker-compose.yml` line 18: change `admin@example.com` to actual email
- Update routing rule (line 53): change `localhost` to your domain
- Ensure ports 80/443 are publicly accessible for Let's Encrypt ACME challenges
- Certificates are persisted in `letsencrypt/acme.json` and auto-renewed

### For Local Development
- Self-signed certificates in `certs/` are used (no ACME challenges needed)
- Access via `https://localhost/` (browser will warn about certificate)
- Use curl with `-k` flag to skip certificate verification

## API Endpoints

| Method | Path | Service | Handler |
|--------|------|---------|---------|
| GET | `/api/welcome` | Spring Boot | WelcomeController.welcome() |
| GET | `/api/actuator/health` | Spring Boot | Spring Actuator |
| * | `/` | Apache | Static HTML |

## Key Implementation Details

- **Spring Boot Version**: 3.3.0 (parent POM)
- **Java Version**: 17 (compilation), 21 (runtime)
- **Build Tool**: Maven 3.9.11
- **Testing Framework**: JUnit 5
- **Docker Base Images**: 
  - Build: maven:3.9.11-eclipse-temurin-21
  - Runtime: eclipse-temurin:21-jre
- **Non-root Container User**: `spring` user in API image (security best practice)

## Debugging

- **Check service logs**: `docker-compose logs <service-name>`
- **Inspect Traefik routing**: Check labels in `docker-compose.yml` and service logs
- **Verify network connectivity**: Services communicate via internal DNS (service name)
- **API port mapping**: Internal port 8888 → exposed via Traefik path `/api`
- **Certificate issues**: Check `letsencrypt/acme.json` for Let's Encrypt storage or `certs/` for manual certs

## Dependencies

### API
- spring-boot-starter-web (REST framework)
- spring-boot-starter-actuator (health check endpoint)
- spring-boot-starter-logging (SLF4J)
- lombok (annotation processing)
- spring-boot-starter-test (JUnit 5, Mockito, etc.)

### Infrastructure
- Docker & Docker Compose
- Traefik v3.7.1
- Apache httpd 2.4

## Additional Resources

See `README.md` for user-facing documentation and architecture diagrams.
