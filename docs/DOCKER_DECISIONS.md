# Docker Decisions

This document explains the containerization choices made for this repository.

## Why Alpine
- Alpine-based Node images are smaller and have a reduced attack surface.
- They minimize image size and startup overhead while still supporting Node LTS.
- This helps keep the development and build environment efficient.

## Why non-root user
- Running containers as a non-root user reduces the blast radius if an attacker compromises the process.
- It follows container security best practices and avoids running application processes with root privileges.
- The Dockerfiles create `appuser` and assign ownership for all copied files.

## Why npm ci
- `npm ci --omit=dev` installs exact dependency versions from `package-lock.json`.
- It produces reproducible builds and avoids dependency drift.
- This is the recommended installation method for production container builds.

## Why HEALTHCHECK
- HEALTHCHECK allows Docker to detect container failures and restart unhealthy services automatically.
- It improves observability for the local compose environment.
- Added checks validate that each service endpoint is responding before traffic is considered healthy.

## Why Docker Compose is only for local development
- Docker Compose is an excellent developer workflow tool, but it is not a production orchestration platform.
- For production, the goal is to use ECS (or another managed container service) because it supports scaling, service discovery, and cloud-native deployment patterns.
- Compose is retained here for local testing, integration, and developer onboarding.

## Why separate frontend and backend networks
- The two-network design reflects the 3-tier architecture and limits service visibility.
- `frontend` network exposes web-to-browser-facing services.
- `backend` network isolates the database and API traffic from the public-facing frontend network.
- This separation improves security and model clarity during local testing.
