# Use a specific Node LTS patch version on Alpine for a small, stable production base.
FROM node:18.20.2-alpine

# OCI labels provide metadata for image inspection and compliance.
LABEL org.opencontainers.image.authors="Sourabh Yogi"
LABEL org.opencontainers.image.description="API service for the secure 3-tier Node.js application"
LABEL org.opencontainers.image.version="1.0.0"

# Create a dedicated non-root user for runtime security.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /usr/src/app

# Keep the runtime environment explicit and production-safe.
ENV NODE_ENV=production

# Copy dependency metadata first with ownership assigned to the non-root user.
COPY --chown=appuser:appgroup package*.json ./

# Install production dependencies from lockfile for reproducible builds.
# This requires package-lock.json to be present in the build context.
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --production; fi

# Copy application source code with ownership for the non-root user.
COPY --chown=appuser:appgroup . .

# Ensure the container runs with non-root privileges.
USER appuser

# The app listens on port 3000 by default, but this can be overridden by PORT at runtime.
EXPOSE 3000

# Healthcheck verifies the configured runtime port using Node.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["node", "-e", "const p=process.env.PORT||3000; const http=require('http'); const req=http.get({hostname:'127.0.0.1', port:p, path:'/api/status'}, res=>{ process.exit(res.statusCode===200?0:1); }); req.on('error', ()=>process.exit(1));"]

CMD ["node", "./bin/www"]
