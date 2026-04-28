---
name: write-dockerfile
description: >
  Creates or updates an optimized, production-ready Dockerfile and .dockerignore.
  Focuses on image build strategy, runtime hardening, caching, and minimal production images.
  Invoked when the user asks to write a Dockerfile, improve container image quality, or harden image builds.
version: 1.1.0
tags:
  - devops
  - docker
  - containers
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Write Dockerfile Skill

Create a production-ready Dockerfile for the current project.
Scope boundary: Dockerfile and image concerns only. For local multi-service orchestration
(`compose.yaml`, service dependencies/readiness, env files, volumes, migrations/seeds),
use `docker-compose-local-setup`.

### Step 1 — Detect Language and Framework

Read: `package.json`, `go.mod`, `pyproject.toml`, `composer.json`, or other manifest files.
Identify:
- Runtime and version (Node 22, Go 1.26, Python 3.12, PHP 8.3)
- Build process (compile, bundle, install dependencies)
- Entry point / start command

### Step 2 — Apply Dockerfile Build and Runtime Best Practices

**Multi-stage build**: separate build stage from runtime stage to keep the final image small.

**Layer caching**: copy dependency manifests first, install, then copy source. This caches the
dependency install layer and only invalidates it when dependencies change.

**Non-root user**: run the application as a non-root user in the final stage.

**Minimal base image**: use official slim/alpine variants for the runtime stage.

**Health check**: include a `HEALTHCHECK` instruction when the runtime supports it.

**No secrets in the image**: all secrets come from environment variables at runtime.

### Step 3 — Write the Dockerfile

Structure:
```dockerfile
# syntax=docker/dockerfile:1
# Stage 1: Build
FROM {build-image} AS builder
WORKDIR /app
# Copy manifests first (cache layer)
COPY {manifest-files} ./
RUN {install-dependencies}
# Copy source and build
COPY . .
RUN {build-command}

# Stage 2: Runtime
FROM {runtime-image}
WORKDIR /app
RUN addgroup --system app && adduser --system --ingroup app app
# Copy only what is needed to run
COPY --from=builder /app/{output} .
USER app
EXPOSE {port}
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD {health-check-command}
CMD ["{start-command}"]
```

### Step 4 — Write `.dockerignore`

Also create or update `.dockerignore` to exclude:
- `.git/`
- `node_modules/` (for Node projects)
- test files, coverage reports
- `.env` files
- `*.md` documentation files

### Step 5 — Verify

Verify:
- image builds successfully with `docker build`
- runtime starts with expected command/entrypoint
- image runs as non-root where applicable
- no secrets are baked into the image layers

State final image size considerations and production hardening notes specific to this project.
