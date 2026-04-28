## Docker Compose Patterns Reference

Use this reference when creating or updating local `compose.yaml` files.

### Service Skeleton

```yaml
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    env_file:
      - .env
    environment:
      APP_ENV: local
    ports:
      - "8080:8080"
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://localhost:8080/health"]
      interval: 10s
      timeout: 3s
      retries: 5
      start_period: 10s
```

### Dependency Services

```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
      POSTGRES_DB: app
    ports:
      - "5432:5432"
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d app"]
      interval: 5s
      timeout: 3s
      retries: 10
```

### Migrations and Seed Jobs

```yaml
services:
  migrate:
    build: .
    command: ["sh", "-c", "npm run migrate"]
    depends_on:
      db:
        condition: service_healthy
    restart: "no"

  seed:
    build: .
    command: ["sh", "-c", "npm run seed"]
    depends_on:
      migrate:
        condition: service_completed_successfully
    restart: "no"
```

### Named Volumes

```yaml
volumes:
  db-data:
  redis-data:
```

### Local Workflow Commands

```bash
docker compose up --build -d
docker compose ps
docker compose logs --tail=200
docker compose exec api sh
docker compose down
docker compose down -v
```

### Verification Checklist

- All required services show `healthy` in `docker compose ps`.
- API can reach its dependencies using compose DNS names.
- Migrations run cleanly from a fresh volume state.
- Restarting with existing volumes preserves expected data.
- `docker compose down -v` reliably resets the stack.
