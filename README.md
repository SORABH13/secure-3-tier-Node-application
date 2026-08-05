# Secure 3-Tier Node Application

This repository contains a simple three-tier Node.js application with separate web and API services.

## Project structure

- `app/api`: Backend API service.
- `app/web`: Frontend web service.
- `docker-compose.yml`: Container orchestration for PostgreSQL, API, and web.
- `PROJECT_ANALYSIS.md`: Architecture and deployment analysis.
- `docs/DECISIONS.md`: Architectural decision log.

## Containerized setup

The application is containerized using Docker Compose and is designed for local or development deployment.

### Build and start

```sh
docker compose up --build
```

### Access

- Web app: `http://localhost:3000`
- API: `http://localhost:3001/api/status`

### Data persistence

PostgreSQL data is stored in a named volume: `postgres_data`.

## Notes

- Both app services are built from official Node LTS images.
- Each app runs as a non-root user inside its container.
- Healthchecks are enabled for PostgreSQL, API, and web services.
- The web service communicates with the API by service name using Docker networking.

## Documentation

Detailed architectural decisions are tracked in `docs/DECISIONS.md`.
