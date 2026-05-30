# FShop - Traefik Example Project

A demonstration project showcasing how to use **Traefik** as a reverse proxy to manage routing, TLS/HTTPS termination, and service discovery for a multi-container application.

## Project Overview

This project demonstrates a modern microservices architecture using Docker Compose with:

- **Traefik** v3.7.1 - Reverse proxy and API gateway
- **Spring Boot API** - Backend API service (Java 17)
- **Apache HTTP Server** - Static frontend hosting
- **HTTPS/TLS** - Automatic certificate management with Let's Encrypt
- **Docker Compose** - Orchestration and networking

## Architecture

```
┌─────────────────────────────────────────────────┐
│         Traefik Reverse Proxy (Port 80, 443)    │
├─────────────────────────────────────────────────┤
│  • HTTP → HTTPS Redirect                         │
│  • TLS Certificate Management (Let's Encrypt)    │
│  • Path-based Routing (/api, /)                  │
│  • Dashboard (available via API)                 │
└─────────────┬───────────────────────────────────┘
              │
    ┌─────────┴──────────┐
    │                    │
    ▼                    ▼
┌──────────────┐  ┌──────────────┐
│  Spring Boot │  │   Apache     │
│     API      │  │   Frontend   │
│  :8888       │  │   :80        │
│  /api/*      │  │  /*          │
└──────────────┘  └──────────────┘
```

## Services

### Traefik
- **Role**: Reverse proxy, load balancer, and TLS terminator
- **Features**:
  - Automatic service discovery via Docker labels
  - HTTP to HTTPS redirection
  - Let's Encrypt integration for automatic certificate renewal
  - Dashboard available (can be configured in docker-compose.yml)
  - Path-based routing to different backends

### FShop API (Spring Boot)
- **Location**: `/api`
- **Port**: 8888 (internal) → exposed at `/api` path
- **Features**:
  - Spring Boot 3.3.0 with Java 17
  - REST API endpoints
  - Health check endpoint: `/actuator/health`
  - Example endpoint: `GET /api/welcome` - returns a welcome message
- **Build**: Maven-based with Docker containerization

### FShop Frontend
- **Location**: `/` (root path)
- **Hosting**: Apache HTTP Server 2.4
- **Files**: Static HTML served from `/ui` directory
- **Functionality**: Loads and displays welcome message from the API

## Getting Started

### Prerequisites

- Docker and Docker Compose
- A domain name (for production Let's Encrypt certificates)
- Local certificates for development (already included in `/certs`)

### Running the Project

1. **Start all services**:
   ```bash
   docker-compose up -d
   ```

2. **Access the application**:
   - Frontend: `https://localhost/`
   - API: `https://localhost/api/welcome`
   - Traefik Dashboard: Configure in docker-compose.yml and access via API

3. **Stop services**:
   ```bash
   docker-compose down
   ```

### Local Development

For local HTTPS testing, the project includes self-signed certificates in `/certs`:
- `cert.pem` - Certificate file
- `key.pem` - Private key

These are loaded by Traefik's dynamic configuration in `traefik-dynamic.yml`.

### Production Configuration

For production deployment:

1. **Update the email in docker-compose.yml**:
   ```yaml
   - --certificatesresolvers.letsencrypt.acme.email=your-email@example.com
   ```

2. **Update the domain in docker-compose.yml**:
   ```yaml
   - traefik.http.routers.springboot.rule=Host(`your-domain.com`)
   ```

3. **Ensure port 80 and 443 are accessible** for Let's Encrypt ACME challenges

4. **Mount `/letsencrypt/acme.json` as a volume** to persist certificate renewals

## Project Structure

```
traefik-example-project/
├── README.md                      # This file
├── docker-compose.yml             # Docker Compose configuration
├── traefik-dynamic.yml            # Traefik dynamic TLS config
├── certs/                         # TLS certificates (local development)
│   ├── cert.pem
│   └── key.pem
├── letsencrypt/                   # Let's Encrypt certificates (auto-renewed)
│   └── acme.json
├── api/                           # Spring Boot API
│   ├── pom.xml
│   ├── src/
│   ├── docker/
│   │   └── fshop-api.dockerfile
│   └── target/
└── ui/                            # Frontend static files
    └── index.html
```

## Configuration Details

### Docker Compose Services

**Traefik Container**:
- Exposes ports 80 (HTTP) and 443 (HTTPS)
- Listens to Docker daemon for service discovery
- Mounts certificates and Let's Encrypt storage
- Auto-redirects HTTP to HTTPS

**Spring Boot Container**:
- Built from `api/docker/fshop-api.dockerfile`
- Internal port: 8888
- Discovered by Traefik via labels
- Routing rule: `PathPrefix(/api)` with path stripping

**Apache Frontend Container**:
- Uses official `httpd:2.4` image
- Serves files from `./ui` directory
- Routing rule: `PathPrefix(/)` (catch-all)
- Runs on port 80

### Traefik Dynamic Configuration

The `traefik-dynamic.yml` file defines:
- TLS certificate paths for local development
- Can be extended with middleware, authentication, etc.

## Networking

- **Network**: `frontend` (bridge driver)
- **DNS**: Container-to-container communication via service names
- **Isolation**: Services are isolated from the host by default

## Usage Examples

### Access the Frontend
```bash
curl -k https://localhost/
```

### Call the API
```bash
curl -k https://localhost/api/welcome
```

### Check API Health
```bash
curl -k https://localhost/api/actuator/health
```

## Development

### Building the API
```bash
cd api
mvn clean package
docker build -f docker/fshop-api.dockerfile -t fshop-api .
```

### Testing
```bash
# Run API tests
cd api
mvn test
```

## Key Features Demonstrated

✅ **Service Discovery** - Traefik automatically discovers services via Docker labels  
✅ **Path-Based Routing** - Different endpoints route to different services  
✅ **HTTPS/TLS** - Automatic certificate management with Let's Encrypt  
✅ **HTTP Redirection** - All HTTP traffic redirects to HTTPS  
✅ **Multi-Service Architecture** - Frontend, API, and reverse proxy working together  
✅ **Docker Compose** - Simple orchestration with clear service definitions  
✅ **Middleware** - Path stripping middleware removes `/api` prefix before forwarding  

## Troubleshooting

### Certificate Issues
- Check `/letsencrypt/acme.json` for Let's Encrypt certificate storage
- Verify port 80 is accessible for ACME challenges
- For local development, the project includes self-signed certificates in `/certs`

### Service Not Found
- Verify service labels in docker-compose.yml include `traefik.enable=true`
- Check Traefik logs: `docker-compose logs traefik`

### HTTPS Certificate Warnings (Local)
- This is expected with self-signed certificates
- Use `-k` flag with curl to ignore certificate verification
- Configure your browser/client to trust the certificate for development

## License

This is an example project for educational purposes.

## References

- [Traefik Documentation](https://doc.traefik.io/)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Let's Encrypt](https://letsencrypt.org/)
