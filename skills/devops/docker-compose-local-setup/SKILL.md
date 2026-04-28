---
name: docker-compose-local-setup
description: >
  Creates or updates local multi-service orchestration using docker compose.
  Covers compose.yaml design, service health checks, depends_on readiness,
  env files, named volumes, migrations/seeds jobs, verification commands,
  and cleanup workflows for local development.
version: 1.0.0
tags:
  - devops
  - docker
  - compose
  - local-development
resources:
  - compose-patterns-reference.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Docker Compose Local Setup Skill

Set up or improve local multi-service orchestration with `docker compose`.

### Step 1 — Model Local Services

Define the local stack in `compose.yaml`:
- app services (API, worker, frontend)
- stateful dependencies (database, cache, broker)
- one-off jobs (migrations, seeds)

Keep local concerns explicit and avoid production-only orchestration details.

### Step 2 — Configure Build, Runtime, and Networking

For each service:
- Use `build:` for local image workflows or `image:` when fixed images are preferred.
- Set deterministic `container_name` only when needed for tooling compatibility.
- Map ports required for local access.
- Use the default compose network unless isolation is required.

### Step 3 — Add Health Checks and Readiness

For services that others depend on:
- Add `healthcheck:` with realistic command, interval, timeout, retries, and start period.
- Prefer `depends_on` with `condition: service_healthy` where supported by your compose implementation.
- If condition-based readiness is unavailable, add explicit wait logic in dependent services.

### Step 4 — Manage Configuration and Secrets for Local Use

- Use `env_file:` for shared local defaults.
- Keep per-service overrides in `environment:`.
- Commit only safe sample files such as `.env.example`.
- Never hardcode credentials in `compose.yaml` or checked-in env files.

### Step 5 — Persist Data and Source Mounts

- Use named volumes for database/cache durability across restarts.
- Use bind mounts for hot-reload source workflows when appropriate.
- Keep mount paths narrow to avoid accidental host pollution.

### Step 6 — Handle Migrations and Seed Data

Define one-off jobs for schema and seed flows:
- migration service/command that runs after dependencies are healthy
- optional seed service for local fixtures
- idempotent commands so repeated local setup is safe

### Step 7 — Verify End-to-End Startup

Run and validate:
1. `docker compose up --build -d`
2. `docker compose ps`
3. `docker compose logs --tail=200`
4. service-specific checks (HTTP health endpoint, DB connectivity)

Document expected healthy state and failure triage steps.

### Step 8 — Cleanup and Reset

Use the right cleanup level:
- stop only: `docker compose stop`
- stop and remove containers/network: `docker compose down`
- full reset including named volumes: `docker compose down -v`

Call out destructive reset commands before running them.

### Step 9 — Keep Scope Boundaries Clear

This skill is for local multi-service orchestration with `docker compose`.
For Docker image authoring and production image hardening, use `write-dockerfile`.
