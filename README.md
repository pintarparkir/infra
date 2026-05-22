# infra

> **Purpose:** Local shared infrastructure — Postgres, Redis, RabbitMQ, OpenTelemetry Collector for development.  
> **Author:** Farid Triwicaksono · **Last Updated:** 2026-05-21

## Overview

This directory provides the **supporting services** that all ParkirPintar microservices depend on during local development:
- **PostgreSQL 16** — primary data store for all services
- **Redis 7** — caching and distributed locking
- **RabbitMQ 3.13** — event bus for async communication
- **OpenTelemetry Collector** — trace/metric aggregation

The Go services themselves (`user-service`, `reservation-service`, `billing-service`, `payment-service`, `notification-service`) run from their own directories via `make run` after this stack is up.

## Services Provided

| Service | Port(s) | Purpose |
|---------|---------|---------|
| **PostgreSQL** | 5432 | Primary database for all services |
| **Redis** | 6379 | Cache + distributed locks |
| **RabbitMQ** | 5672 (AMQP), 15672 (UI) | Event bus + DLQ |
| **OTel Collector** | 4317 (OTLP/gRPC), 4318 (OTLP/HTTP) | Trace/metric collection |

## Quick Start

### Prerequisites
- Docker 24+ & Docker Compose v2 (or Podman)
- macOS users: Homebrew (for RabbitMQ workaround)

### Start Infrastructure

**Linux / Docker Desktop:**
```bash
cd infra
docker compose up -d
```

**macOS / Podman:**
```bash
# RabbitMQ via Homebrew (Podman rootless issue workaround)
brew install rabbitmq
brew services start rabbitmq

# Postgres + Redis + OTel via containers
cd infra
podman compose up -d
```

### Verify Services

```bash
# PostgreSQL
psql "postgres://postgres:postgres@localhost:5432/postgres" -c '\l'

# Redis
redis-cli -h localhost ping

# RabbitMQ
rabbitmqctl status                    # if using brew
curl http://localhost:15672           # management UI (guest/guest)

# OTel Collector
curl -sf http://localhost:4317/       # OTLP gRPC port
```

## Per-Service Databases

PostgreSQL init script (`postgres/init/00-create-databases.sql`) creates one database per service on first start:
- `user_service`
- `reservation_service`
- `billing_service`
- `payment_service`

Each service applies its own migrations via `golang-migrate` (see service's `data/migrations/` and `scripts/migrate.sh`).

### Manual Migration (if golang-migrate not installed)

```bash
# user-service
psql "postgres://postgres:postgres@localhost:5432/user_service?sslmode=disable" \
  -f ../user-service/data/init.sql

# reservation-service
psql "postgres://postgres:postgres@localhost:5432/reservation_service?sslmode=disable" \
  -f ../reservation-service/data/migrations/001_init.up.sql
psql "postgres://postgres:postgres@localhost:5432/reservation_service?sslmode=disable" \
  -f ../reservation-service/data/migrations/002_pending_in_exclude.up.sql
psql "postgres://postgres:postgres@localhost:5432/reservation_service?sslmode=disable" \
  -f ../reservation-service/data/seed.sql

# billing-service
psql "postgres://postgres:postgres@localhost:5432/billing_service?sslmode=disable" \
  -f ../billing-service/data/migrations/001_init.up.sql

# payment-service
psql "postgres://postgres:postgres@localhost:5432/payment_service?sslmode=disable" \
  -f ../payment-service/data/migrations/001_init.up.sql
```

## Configuration

### PostgreSQL
- **User:** `postgres`
- **Password:** `postgres`
- **Port:** `5432`
- **Config:** `postgres/postgresql.conf` (tuned for dev)

### Redis
- **Port:** `6379`
- **Password:** none (dev only)
- **Config:** `redis/redis.conf`

### RabbitMQ
- **AMQP Port:** `5672`
- **Management UI:** `http://localhost:15672` (guest/guest)
- **Exchange:** `parkirpintar.events` (topic)
- **Config:** `rabbitmq/rabbitmq.conf`

### OpenTelemetry Collector
- **OTLP/gRPC:** `4317`
- **OTLP/HTTP:** `4318`
- **Config:** `otel/config.yaml`

## Troubleshooting

### PostgreSQL won't start
```bash
# Check logs
docker compose logs postgres

# Reset data volume
docker compose down -v
docker compose up -d
```

### Redis connection refused
```bash
# Verify Redis is running
docker compose ps | grep redis

# Test connection
redis-cli -h localhost ping
```

### RabbitMQ permission issues (macOS/Podman)
```bash
# Use Homebrew RabbitMQ instead
brew install rabbitmq
brew services start rabbitmq

# Verify
rabbitmqctl status
```

### OTel Collector not receiving traces
```bash
# Check collector logs
docker compose logs otel-collector

# Verify port is open
lsof -i :4317
```

## Tear Down

```bash
cd infra

# Stop containers, keep volumes
docker compose down

# Stop containers and wipe data
docker compose down -v

# Stop Homebrew RabbitMQ (if using)
brew services stop rabbitmq
```

## Production Analogue

| Local | Production |
|-------|------------|
| postgres container | Cloud SQL `db-f1-micro` per service |
| redis container | Memorystore Basic 1 GB |
| rabbitmq (brew/container) | CloudAMQP Lemur or GCE e2-micro |
| otel-collector | Managed collector (Honeycomb/Tempo) |

## Service Links

- **user-service:** [`../user-service/README.md`](../user-service/README.md)
- **reservation-service:** [`../reservation-service/README.md`](../reservation-service/README.md)
- **billing-service:** [`../billing-service/README.md`](../billing-service/README.md)
- **payment-service:** [`../payment-service/README.md`](../payment-service/README.md)
- **notification-service:** [`../notification-service/README.md`](../notification-service/README.md)

## Related Documentation

- **Architecture Overview:** [`../docs/README.md`](../docs/README.md)

---

_For questions or issues, refer to the troubleshooting section above or the main project README._
