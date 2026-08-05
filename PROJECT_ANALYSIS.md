# Project Analysis

## 1. Application overview

This repository contains a simple 3-tier Node.js application separated into two distinct tiers:

- `app/api`: Backend API tier implemented with Express and PostgreSQL.
- `app/web`: Frontend web tier implemented with Express and Jade templates.

The web tier renders a single page and fetches runtime data from the API tier. The API tier connects to a PostgreSQL database and returns a timestamp.

## 2. Repository structure

- `app/`
  - `api/`
    - `README.md`
    - `package.json`
    - `app.js`
    - `bin/www`
  - `web/`
    - `README.md`
    - `package.json`
    - `app.js`
    - `bin/www`
    - `routes/`
      - `index.js`
    - `views/`
      - `index.jade`
      - `layout.jade`
    - `public/`
      - `images/`
      - `stylesheets/`
        - `style.css`

## 3. Frontend architecture

The frontend is a server-rendered Express application in `app/web`.

- Uses Express middleware: `morgan`, `body-parser`, `cookie-parser`, and `serve-favicon`.
- Uses Jade templates (`view engine` set to `jade`) to render HTML.
- Serves static assets from `app/web/public`.
- Main route `/` in `routes/index.js` performs an HTTP GET request to the backend API and injects response values into the rendered page.

## 4. Backend architecture

The backend is a minimal Express API in `app/api`.

- Exposes a single endpoint: `GET /api/status`.
- Uses `pg` to connect to PostgreSQL, and `node-uuid` is installed though not used in current code.
- Reads database connection settings from environment variables.
- Queries `SELECT now() as time` and returns result rows as JSON.
- Uses Express error handling for 404 and other failures.

## 5. Database architecture

The API tier uses PostgreSQL via the `pg` module.

- Connection configuration comes from environment variables: `DBUSER`, `DB`, `DBPASS`, `DBHOST`, `DBPORT`.
- No schema or migration files are present in the repository.
- Current database interaction is a single simple query returning the current server time.

## 6. Request flow

1. Client browser requests `/` from the web tier.
2. The web tier route handler builds an API URL using `process.env.API_HOST + '/api/status'`.
3. The web server sends an HTTP GET request to the API tier.
4. The API tier connects to PostgreSQL, executes `SELECT now() as time`, and returns JSON.
5. The web tier receives the JSON payload and renders `views/index.jade`.
6. The rendered page displays the timestamp and a request UUID value.

> Note: The API actually returns only `time`, while the web view expects `request_uuid` and `time`. This is a functional inconsistency.

## 7. Environment variables

### API tier (`app/api`)
- `PORT`: HTTP listen port for the API service.
- `DB`: PostgreSQL database name.
- `DBUSER`: PostgreSQL username.
- `DBPASS`: PostgreSQL password.
- `DBHOST`: PostgreSQL host.
- `DBPORT`: PostgreSQL port.

### Web tier (`app/web`)
- `PORT`: HTTP listen port for the web service.
- `API_HOST`: Full URL of the API service, including protocol and host, used to call `/api/status`.

## 8. Ports

- Both tiers default to port `3000` when `PORT` is not defined.
- Each tier is independent and should run on separate ports or hosts.
- The web tier must be able to reach the API tier on the configured `API_HOST`.

## 9. Dependencies

### API dependencies
- `express` ~4.13.1
- `pg` 8.2.1
- `node-uuid` 1.4.7

### Web dependencies
- `body-parser` ~1.13.2
- `cookie-parser` ~1.3.5
- `debug` ~2.6.9
- `express` ~4.13.1
- `jade` ~1.11.0
- `morgan` ~1.6.1
- `redis` ^1.0.0
- `redis-url` ^1.2.1
- `serve-favicon` ~2.3.0
- `request` 2.72.0

> Note: `redis` and `redis-url` are installed in the web tier but are not used in the current source.

## 10. Build process

- There is no explicit build process in this repository.
- Both tiers are plain Node.js applications.
- The expected preparation step is `npm install` in each tier directory.

## 11. Startup process

### API tier
- Run `npm install` in `app/api`.
- Set required database environment variables.
- Start with `npm start`.
- The API starts via `node ./bin/www`.

### Web tier
- Run `npm install` in `app/web`.
- Set `PORT` and `API_HOST` environment variables.
- Start with `npm start`.
- The web tier starts via `node ./bin/www`.

## 12. Production deployment considerations

- Deploy API and web tiers as separate services or containers.
- Use a reverse proxy/load balancer to route traffic to the web tier and protect API access.
- Set `NODE_ENV=production` for both tiers.
- Secure environment variables and avoid committing secrets.
- Use a process manager such as PM2, systemd, Docker, or Kubernetes.
- Ensure `API_HOST` uses HTTPS (or internal secure network) and is not exposed without access control.
- Enable monitoring and health checks for both tiers.

## 13. Security concerns

- No authentication or authorization is implemented.
- The web tier trusts `API_HOST` and performs a request without verification.
- Production error handling is minimal and stack traces may still be exposed by mistake if `NODE_ENV` is not set correctly.
- Database credentials are passed via environment variables; secret management is required.
- The web route renders data into Jade templates without explicit output escaping, though Jade does HTML escaping by default.
- The `request` library is deprecated; using a maintained HTTP client is recommended.
- `node-uuid` is deprecated in favor of `uuid`.

## 14. Scaling considerations

- The architecture is stateless at the web and API tiers, so horizontal scaling is feasible.
- The API currently creates and destroys a `pg.Pool` for every request, which will not scale and can exhaust DB connections.
- A better approach is to instantiate a shared pool once per API process.
- The database is a single point of scaling contention and will need pooling, read replicas, or a managed service for higher load.
- Use a load balancer in front of multiple web and API instances.
- Cache responses at the web tier or API tier if the data is not always fresh.

## 15. Possible improvements

- Fix the mismatch between API response payload and the web view expectations.
- Move `pg.Pool` creation to module scope in `app/api/app.js` to reuse connections.
- Remove unused dependencies such as `redis`, `redis-url`, and `node-uuid` if they are not needed.
- Replace `request` with a modern HTTP client like `node-fetch`, `axios`, or native `fetch`.
- Add explicit health and readiness endpoints for deployment orchestration.
- Add proper input validation and error handling in both tiers.
- Add automated tests for routing and database integration.
- Introduce configuration management for environment variables, e.g. `dotenv` for local development.
- Harden production deployment with TLS, security headers, and network segmentation.
- Add logging and request tracing for observability.
