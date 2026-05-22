# ADR-002: Single-tenant MVP, defer multi-building abstraction

**Status:** Accepted  
**Date:** 2026-04-27

## Context
Soal explicitly scopes ParkirPintar to **a single fixed parking area** (1 building, 5 floors). Future expansion to multi-building is plausible but not in scope.

## Decision
- DB schema includes a `spot.id` like `F2-C-014` (floor, vehicle code, slot index) but **no `building_id`** column at MVP.
- All services hardcode the single building's geofence (lat/lon) in config.
- Pricing rules are global (per soal); no building-level overrides.

## Why
- YAGNI: introducing `building_id` everywhere now adds JOIN cost and config complexity for zero current benefit.
- Schema migration to add `building_id` later is straightforward (`ALTER TABLE` + backfill = 1 small migration).

## Migration Path (when multi-building needed)
1. Add `building_id` column with default `'BLDG-001'` (NOT NULL after backfill).
2. Add `building` table with geofence, timezone, pricing override.
3. Update all queries to filter by `building_id` (compile error driven).
4. Update gateway routing: `/v1/buildings/:id/availability`.

Estimated effort: 2 dev-days. Acceptable cost of deferral.

## Consequences
- **+** Simpler MVP code, fewer bugs.
- **−** Future migration touches every service. Acceptable since we know the migration is small.
