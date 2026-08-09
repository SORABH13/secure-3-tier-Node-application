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

## CI/CD authentication

### Why static credentials instead of GitHub OIDC, given the IAM roles for OIDC already exist?
- OIDC federation (`infrastructure/modules/iam`, `enable_github_oidc`) was built and applied first: an `aws_iam_openid_connect_provider` plus two roles trusted via a `sub`-claim condition scoped to this repo.
- In practice, GitHub never granted the `id-token` permission to any job -- confirmed by the run's own "Permissions" panel never listing `id-token`, across 5+ real CI runs and three different trust-policy subject formats (exact ref, environment-scoped, repo-wildcard). That is a GitHub-platform-level restriction, not something fixable from workflow YAML or the IAM trust policy.
- Rather than block both pipelines indefinitely on a platform issue outside this repo's control, `app.yml`/`infra.yml` were reverted to short-lived STS credentials stored as GitHub Actions secrets (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`/`AWS_SESSION_TOKEN`) so deploys keep working.
- The OIDC provider and roles were deliberately left in Terraform rather than removed -- re-enabling OIDC once the platform-side restriction lifts is a credentials-step change in the two workflow files, not new infrastructure. See `docs/DEPLOYMENT_GUIDE.md` for the exact swap-back steps.

## Documentation

### Why keep `docs/DECISIONS.md`?
- Provides a living record of architectural rationale.
- Supports interview discussions by making design choices explicit.
- Helps future maintainers understand why the current solution was selected.
