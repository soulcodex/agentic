## Go Standard Layout

Follow the [community-standard Go project layout](https://github.com/golang-standards/project-layout)
to keep large codebases navigable and idiomatic.

### `/cmd`

One sub-directory per binary. Each `main.go` wires the application together —
flag parsing, dependency injection, signal handling. No business logic lives here.

```
cmd/
  myservice/main.go
  migrator/main.go
```

### `/internal`

Go-enforced private code. Not importable by external modules. Organise by layer:

```
internal/
  domain/         ← entities, value objects, repository interfaces
  application/    ← use cases, command/query handlers
  infrastructure/ ← DB adapters, HTTP clients, messaging
```

### `/pkg`

Exported library code that other modules may import. Promote from `/internal`
only when the code is genuinely reusable and you are ready to maintain a stable
public API. Prefer keeping code in `/internal` until reuse is proven.

### `/api`

Machine-readable API definitions: OpenAPI/Swagger specs, Protocol Buffer files,
JSON Schema files, and generated stubs. Do not place hand-written business logic
here.

### `/web`

Server-rendered or embedded frontend assets: static files, templates, and any
frontend build output embedded into the binary via `//go:embed`.

### `/configs`

Configuration file templates and defaults (`config.yaml.example`,
`default.toml`). **Never store secrets or environment-specific values here.**

- Centralize configuration loading and validation in one package.
- Support both env-driven and file-driven configuration when needed.
- Keep a maintained `.env.example` aligned with required runtime variables.

### `/scripts`

Development and CI shell scripts — linting wrappers, database seeders,
code-generation helpers. These are not executed at production runtime.

- Scripts should be idempotent and callable from `just`/`make`.
- Keep environment setup and repetitive quality tasks scripted, not manual.

### `/build`

Everything needed to package the application: Dockerfiles, package manifests
(`.deb`, `.rpm`), CI artifact configuration.

```
build/
  Dockerfile
  package/
    Dockerfile.alpine
```

- Keep deployable Docker artifacts under `/build` to separate packaging from runtime code.

### `/deployments`

Infrastructure and orchestration configuration: Kubernetes manifests, Helm
charts, `docker-compose.yml`, Terraform modules. Separating this from `/build`
keeps packaging concerns apart from deployment concerns.

- Provide local `docker-compose` environments close to production dependencies.

### `/test`

Additional integration and end-to-end test data and helpers. Unit tests belong
alongside the code they test (`*_test.go`) — do not move unit tests here.

```
test/
  fixtures/
  e2e/
  testdata/
```

### `/migrations`

Versioned database migrations (`up`/`down`) live here.

- Prefer explicit SQL migrations over opaque ORM auto-migrations in domain-heavy systems.
- Migration files are part of application history and must be reviewed like code.

### `/schemas`

Schema files for validating external input (JSON Schema/OpenAPI/Avro/Proto).

- Use schema files at adapter boundaries (HTTP/webhooks/events).
- Keep filenames versioned and domain-specific.

---

### When to Use Each Directory

| Directory | Use when … |
|-----------|-----------|
| `/cmd` | You need a standalone binary entry point |
| `/internal` | Code is private to this module (default for new code) |
| `/pkg` | Code is a reusable library with a stable public API |
| `/api` | You have OpenAPI, Protobuf, or JSON Schema definitions |
| `/web` | You embed a frontend or server-rendered templates |
| `/configs` | You ship config templates or default config files |
| `/scripts` | You have dev/CI helper scripts not used at runtime |
| `/build` | You have Dockerfiles or packaging configuration |
| `/deployments` | You have k8s/Helm/Terraform/Compose files |
| `/test` | You have E2E fixtures or shared test helpers |
| `/migrations` | You version database changes with up/down scripts |
| `/schemas` | You validate external payload contracts via schema files |

### Workflow Conventions

- Keep user-facing project automation in `justfile` (or `Makefile`) so setup/lint/test/migrate
  commands are discoverable and repeatable.
- Enforce correctness/style with `golangci-lint` and treat config as part of the architecture.
- Keep `go:generate` directives near interfaces when generating mocks/stubs.
- Use query builders or explicit SQL in DAL adapters when domain mapping control matters.
