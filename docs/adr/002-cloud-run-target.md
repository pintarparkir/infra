# ADR-006: Cloud Run as default compute target

**Status:** Accepted  
**Date:** 2026-04-27

## Context
We need to deploy 6 Go services to production cheaply, with low ops overhead, and supporting gRPC/HTTP2.

## Decision
Use **GCP Cloud Run** as the default production target. Document portability to AWS Fargate and self-hosted (Hetzner).

## Why Cloud Run
- **Scale-to-zero** for non-critical services → ~$0 cost when idle.
- **gRPC + HTTP/2 native** support since 2020.
- **Zero ops** for OS patching, runtime upgrades.
- **Built-in mTLS** between services on the same project.
- **Cheap egress** to other GCP services (Cloud SQL).

## Alternatives Considered
| Option | Why not default |
|---|---|
| GKE (k8s) | Operational overhead too high for MVP team size; ~$72/mo for control plane alone. |
| AWS ECS Fargate | Equivalent capability, similar price. Documented as alternative. |
| Self-hosted (Hetzner CCX23, ~$15/mo) | Lowest absolute cost but full ops burden. Documented as cost-optimized fallback. |
| Heroku/Render | Easy but expensive at scale; no native gRPC streaming support on free tier. |

## Constraints
- Cloud Run request timeout 60min max → fine for our flows.
- No persistent disk → all state in Postgres/Redis (already true).
- Cold start ~2s for Go binary → mitigate by setting `min_instances=1` for `gateway` and `reservation` (critical paths).

## Cost estimate (see README §11)
~$30–40/month for full MVP stack. ~$0.04 per active hour per service.

## Trigger to revisit
- Need for sticky sessions / WebSockets (Cloud Run supports but with caveats).
- Latency budget < 100ms p99 globally (then consider edge compute).
