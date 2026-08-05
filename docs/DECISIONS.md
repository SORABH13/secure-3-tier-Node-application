# Architectural Decisions

This document captures major architectural, deployment, and implementation decisions for the secure 3-tier Node.js application.

## Containerization

### Why Docker Compose?
- Chosen for local development and simple multi-service orchestration.
- Allows running PostgreSQL, API, and web services together with minimal configuration.
- Avoids adding full Kubernetes complexity for this repository and interview context.

### Why separate containers for web and API?
- Enforces explicit service boundaries between frontend and backend.
- Supports independent scaling and deployment paths.
- Keeps security and runtime concerns isolated.

### Why PostgreSQL in Docker?
- Official `postgres:16-alpine` image is lightweight and production-appropriate for containerized databases.
- Provides a consistent development environment without needing a host database install.
- Named volume `postgres_data` preserves data across container restarts.

## Runtime Environment

### Why official Node LTS images?
- Node LTS images are stable and widely supported.
- `node:20-alpine` is used to minimize image size while retaining compatibility.
- Alpine-based images reduce attack surface and dependency overhead.

### Why non-root containers?
- Running as a dedicated non-root user (`appuser`) improves container security.
- Reduces risk of privilege escalation if a process is compromised.
- Aligns with container best practices for production workloads.

## Health and readiness

### Why HEALTHCHECK?
- Ensures Docker can detect unhealthy services and restart them automatically.
- Useful for both local development and production orchestration.
- Added for PostgreSQL, API, and web services to validate runtime readiness.

## Build and dependency management

### Why install production dependencies only?
- Keeps container images smaller by excluding development-only packages.
- Faster image builds and reduced runtime footprint.
- The repository does not require build tooling beyond runtime dependencies.

## Network and service wiring

### Why `API_HOST=http://api:3001`?
- Leverages Docker Compose DNS so the web service can resolve the API service by name.
- Removes the need for hardcoded hostnames or local machine networking hacks.
- Simplifies the local deployment model while preserving the same service contract.

## Documentation

### Why keep `docs/DECISIONS.md`?
- Provides a living record of architectural rationale.
- Supports interview discussions by making design choices explicit.
- Helps future maintainers understand why the current solution was selected.
