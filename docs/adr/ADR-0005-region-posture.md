# ADR-0005 — Both Australian Regions active

Status: Accepted · Date: 2026-07-19 · Part: Organisation (decision 3) ·
Supersedes: an earlier pilot-light draft

## Context

Australian Regions only — `ap-southeast-2` (Sydney) and `ap-southeast-4`
(Melbourne) — sovereignty made concrete. Three postures were on the
table: Sydney-only with backup elsewhere; Sydney primary with Melbourne
pilot light; both Regions active.

## Decision

**Both Regions active, on the recovery number.** The agency panel terms
commit Kestrel to recovery measured in minutes for business-critical
services, and the ISM makes continuity the CISO's standing obligation.
Pilot light cannot meet a number like that honestly: its recovery time
is however long a scale-up takes on the worst day, and the first real
measurement happens during the incident. A Region already serving
traffic has no such unknown. Either Region carries the whole load,
sized so single-Region full-estate load is a scaling event, not a
redesign.

This **reverses the earlier pilot-light draft**, which rested on
Melbourne's service catalogue lagging Sydney's. That constraint is now a
gate rather than a blocker: a workload may only land in a zone whose
services exist in both Regions; anything genuinely Sydney-pinned is an
`Exceptions` entry with its own continuity story.

## Consequences

Roughly double the standing infrastructure spend, two estates to patch
and keep coherent, and data consistency becomes a real design problem —
bought because a recovery time nobody has measured is not a recovery
time. The network makes the claim true: two independent egress estates,
one shared edge, a peering link carrying no default route (Networking
decision 9) — a Melbourne that reaches the internet through Sydney is a
pilot light with better marketing.
