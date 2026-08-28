## CI/CD

### Continuous Integration

Every push to a feature branch must trigger:
1. **Lint** — code style and static analysis (fail fast, runs first)
2. **Unit tests** — fast, no external dependencies
3. **Build** — compile / bundle the artifact
4. **Integration tests** — against real dependencies in containers (testcontainers, docker-compose)
5. **Security scan** — dependency audit, SAST (fail on critical/high severity)

For TypeScript projects, lint should run the repository's JS/TS static analysis
tool before tests. New Rsbuild projects should use Rslint when its rule coverage
fits the repo. Conventional Commit enforcement belongs in a commitlint hook or a
CI commit-range check.

For pnpm 12 projects, install pnpm directly in CI. Do not use Corepack to install
or prepare pnpm.

The total CI time for a feature branch should be under 10 minutes. If it exceeds this,
parallelize steps or investigate slow tests.

### Pipeline Conventions

- Use a single pipeline definition file (`.github/workflows/ci.yml`, `.gitlab-ci.yml`, etc.).
- Pin action/image versions to a SHA or version tag — never use `:latest` in CI.
- Cache dependency directories between runs (`node_modules`, Go module cache, pip cache, Composer cache).
- Fail the pipeline immediately on the first error in a step — do not continue past failures.
- Store test reports and coverage artifacts for review even on failure.

### Environment Gates

| Environment | Trigger | Approval required |
|---|---|---|
| Development | Auto on feature branch | No |
| Staging | Auto on merge to `main` | No |
| Production | Manual trigger or tag push | Yes (at least one approver) |

- Staging must mirror production configuration as closely as possible.
- No code is deployed to production that has not first been deployed to and verified on staging.

### Artifact Management

- Build the artifact once, promote it across environments — never rebuild from source for staging
  and production separately.
- Tag container images with the git commit SHA: `my-service:a1b2c3d4`.
- Also tag with semantic version on release: `my-service:v1.2.3`.
- Retain at least the last 10 production images for rollback.

### Deployment Strategy

- **Blue/green**: zero-downtime deployments by running two environments and switching traffic.
- **Canary**: release to a percentage of traffic; monitor for errors before full rollout.
- **Rolling**: gradually replace instances. Simple, supported by Kubernetes natively.

Choose based on risk tolerance and infrastructure. At minimum, use rolling with a readiness check.

### Rollback

- Every deployment must be rollback-able in under 5 minutes.
- Rollback is a forward operation: deploy the previous known-good image.
- Database migrations must be backward-compatible — the old code must work with the new schema
  while the rollback is in progress.
- Never run destructive migrations (drop column, drop table) in the same deployment as application
  code changes. Separate them by at least one deploy cycle.

### Secrets in CI

- Never hardcode secrets in pipeline files.
- Use the CI platform's secrets store (GitHub Secrets, GitLab CI Variables, etc.).
- Rotate CI secrets regularly and on team member departure.
