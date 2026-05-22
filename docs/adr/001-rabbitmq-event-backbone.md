# ADR-001: RabbitMQ over Kafka/NATS for the event backbone

**Status:** Accepted  
**Date:** 2026-04-27  
**Decider:** Backend lead

## Context
We need a durable async messaging backbone for at-least-once delivery (notification dispatch, audit, analytics fan-out). Volume at MVP < 50 events/sec.

## Decision
Use **RabbitMQ** with a single topic exchange (`parkirpintar.events`) and routing keys per event type (e.g., `reservation.confirmed.v1`).

## Why
- **Aligns with the company's B.3 Library standard**, which lists RabbitMQ (`amqp091-go`) as the approved queue technology. Aligning here reduces ops/onboarding cost across the org.
- **Mature operational tooling** — management UI, well-understood backpressure semantics.
- **Topic-exchange + routing keys** map naturally to our event taxonomy (`reservation.confirmed.v1`, `billing.invoice.opened.v1`, ...) and let consumers subscribe per pattern.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| **RabbitMQ (chosen)** | B.3 standard; mature; topic exchange fits per-event-type fan-out; ~$5/mo to self-host | Less suitable for stream replay or compaction |
| Kafka | Industry standard for streaming; strong ordering per partition | Heavy ops (KRaft/ZK); ~$50+/mo managed; overkill at our scale |
| NATS JetStream | Single binary, embeddable for tests, very fast | Not on B.3 standard list — would require new ops runbooks |
| Cloud Pub/Sub | Fully managed | Vendor lock; cost grows with retention |

## Consequences
- **+** Aligns with company standard — easier onboarding, reuses ops tooling.
- **+** Cheap to self-host on a small VM at MVP.
- **−** If we later need stream processing (Flink/ksqlDB) we'd migrate to Kafka. Migration is decoupled via the outbox pattern — only the publisher (and consumer) implementation changes.
- **−** RabbitMQ doesn't compact or replay over arbitrary windows. We accept this; for any analytics use-case, we'd consume into a separate sink.

## Trigger to revisit
- Sustained volume > 5k events/sec
- Need for log-compacted topics or arbitrary replay
- Multi-region active-active replication
