# Security documentation

The IRAP assessment pack for the Kestrel AWS Landing Zone — the four documents an
assessor expects before an engagement, plus the control register they index into.

> Kestrel Digital is a **fictional scenario** and this is a reference implementation.
> **Nothing here has been IRAP assessed** — the work in [`docs/assessment/`](../assessment/)
> is a self-assessment on IRAP methodology, which is not an IRAP assessment. That requires
> an ASD-endorsed registered assessor.

## The pack

| Document | Answers | Read it for |
|----------|---------|-------------|
| [System Security Plan](system-security-plan.md) | What is the system and how is it built? | Boundary, architecture, data flows, the responsibility split, control narrative across 27 chapters |
| [SSP Annex](../assessment/matrix.yaml) | Is each control met? | One row per applicable control on the pinned ISM release, with an evidence reference or an owned gap |
| [Security Risk Management Plan](security-risk-management-plan.md) | What could go wrong, and what do we accept? | 13 risks, inherent → residual ratings, treatments, and the acceptance basis |
| [Continuous Monitoring Plan](continuous-monitoring-plan.md) | How does posture hold between assessments? | Drift, coverage, evidence lifecycle, ISM release handling, metrics |
| [Incident Response Plan](incident-response-plan.md) | What happens when something goes wrong? | Severity model, routing, the five response phases, six scenario playbooks |

All four pin **ISM June 2026** (`2026.06`), matching
[`matrix.yaml`](../assessment/matrix.yaml). Re-pinning is a deliberate reviewed event —
see [CMP §7](continuous-monitoring-plan.md#7-ism-release-change-management).

## How they fit together

```text
            SSP ── describes the system ──────────────┐
             │                                        │
             ├── controls ──► SSP Annex (matrix.yaml) │
             │                    │                   │
             │                    ▼                   ▼
             │              evidence objects    system boundary
             │              irap/phase-<n>/     scopes all four
             │                    ▲
             │                    │
            SRMP ── risks ────────┤ ── treatments cite SSP sections
             │                    │
             │                    │
            CMP ── keeps it true ─┤ ── regenerates evidence, catches drift
             │                    │
             ▼                    │
            IRP ── when it fails ─┘ ── post-incident findings feed SRMP + CMP
```

The loop is deliberate: incidents produce findings, findings change risk ratings, changed
risks change what is monitored, and monitoring produces the evidence the Annex references.

## The two rules

Both come from [`docs/assessment/README.md`](../assessment/README.md) and govern every
document here:

1. **Nothing is produced for the assessment.** A claim with no existing evidence object is
   a finding, not a request to go make one.
2. **The matrix never contains evidence** — references only, so the Object-Locked archive
   stays the single source and the matrix stays cheap to diff.

## Open items, disclosed

| Ref | Item | Owner | Expiry |
|-----|------|-------|--------|
| FIND-019 | Application control not enforced on all managed endpoints (ISM-1553) | platform-team | 2026-12-01 |
| R-05 | ~60 brownfield accounts in detective-only posture pending graduation | platform-team | 2027-06-30 |
| R-09 | CloudTrail data events scoped to `kestrel-protected-` buckets on cost grounds | platform-team | Annual review |
| R-10 | `WorkloadDeploy` uses `PowerUserAccess` | platform-team | Flip on first agency-facing Prod workload |
| — | ISM-2104–2107 personnel disclosure — policy control, no technical enforcement point | CISO | Annual acknowledgement |

Closed: **FIND-012** (Melbourne replica retention) — fixed in PR #214, battery gained the
replica-retention test it had lacked.

## Not yet written

Standard Operating Procedures are referenced by the IRP (on-call roster, notification
contact points, full runbooks) and are held operationally rather than in this repository.
