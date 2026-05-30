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

### Production Deployment

To deploy this project to production with Let's Encrypt HTTPS certificates:

#### 1. **Pre-Deployment Requirements**

- A public domain name (e.g., `app.example.com`)
- A server with ports 80 and 443 publicly accessible
- An email address for Let's Encrypt certificate notifications
- SSH access to the production server
- Docker and Docker Compose installed on the server

#### 2. **Prepare the Configuration**

Create a production `.env` file or update `docker-compose.yml`:

```bash
# Set production environment variables
export DOMAIN=your-domain.com
export LETSENCRYPT_EMAIL=your-email@example.com
```

Update the following in `docker-compose.yml`:

```yaml
# Line 18: Update the email for Let's Encrypt notifications
- --certificatesresolvers.letsencrypt.acme.email=your-email@example.com

# Line 53 & 63: Update the domain (replace localhost)
# Before: traefik.http.routers.springboot.rule=Host(`localhost`)
# After:  traefik.http.routers.springboot.rule=Host(`your-domain.com`)
```

**Remove the self-signed certificate mount** from the Traefik service in `docker-compose.yml`:

```yaml
# DELETE THESE LINES from docker-compose.yml (Traefik service volumes):
# Use the dynamic configuration
- --providers.file.directory=/etc/traefik/dynamic
- --providers.file.watch=true
- ./traefik-dynamic.yml:/etc/traefik/dynamic/dynamic.yml:ro
# Certificates configurations
- ./traefik-dynamic.yml:/etc/traefik/dynamic/dynamic.yml:ro
# Access to my certificates
- ./certs:/certs:ro

# In production, Traefik uses Let's Encrypt instead of the local dynamic config
```

#### 3. **Remove Development Certificates**

Delete the self-signed certificates directory (used only for local development):

```bash
rm -rf certs/
```

Traefik will automatically generate Let's Encrypt certificates on first run. The certificates will be stored in `letsencrypt/acme.json`.

#### 4. **Set DNS Records**

Point your domain's A record to your server's public IP address:

```
A  your-domain.com  → your-server-ip
```

Wait for DNS propagation (usually 5-30 minutes).

#### 5. **Deploy to Production**

```bash
# Start all services
cd /app/fshop
docker-compose up -d
# Verify services are running
docker-compose ps
# Check Traefik logs for Let's Encrypt certificate generation
docker-compose logs -f traefik
```

#### 6. **Verify the Deployment**

Once Traefik has acquired a certificate (watch logs for "challenge solved"):

```bash
# Access the frontend
curl https://your-domain.com/
# Test the API
curl https://your-domain.com/api/welcome
# Check API health
curl https://your-domain.com/api/actuator/health
```

All requests should now use valid Let's Encrypt HTTPS certificates (no certificate warnings).

#### 7. **Maintenance & Certificate Renewal**

- **Certificate Renewal**: Traefik automatically renews certificates 30 days before expiration
- **Certificate Storage**: Certificates are stored in `letsencrypt/acme.json` - **back this file up**
- **Rate Limiting**: Let's Encrypt has rate limits; see [their documentation](https://letsencrypt.org/docs/rate-limits/)
- **Logs**: Monitor Traefik logs regularly for certificate issues:
  ```bash
  docker-compose logs traefik
  ```

#### 8. **Production Checklist**

- [ ] Domain name registered and DNS configured
- [ ] Ports 80 and 443 publicly accessible
- [ ] `docker-compose.yml` updated with production domain
- [ ] `docker-compose.yml` updated with valid email address
- [ ] `certs/` directory removed (self-signed certs no longer needed)
- [ ] `letsencrypt/` directory created and writable
- [ ] Services deployed with `docker-compose up -d`
- [ ] Traefik logs confirm certificate acquisition
- [ ] HTTPS requests work without certificate warnings
- [ ] `letsencrypt/acme.json` is backed up regularly

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
