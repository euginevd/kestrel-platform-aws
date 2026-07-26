# 07 — Evidence register

> **NOT AN IRAP ASSESSMENT.** The author is not an ASD-endorsed IRAP assessor. See
> [README](README.md).

Records the assessment objects examined, the quality of evidence each provided, and — per
IRAP-AR-0005 — the evidence that could not be obtained and the impact of its absence.

## 1. Evidence quality scale (IRAP-AR-0026)

The CAF's four levels, and what each requires:

| Level | Requires | Available here |
|-------|----------|----------------|
| **Excellent** | Examining, testing or reviewing firsthand the activities or mechanisms demonstrating the control operates — e.g. attempting an action to confirm it is blocked | **No** |
| **Good** | Reviewing technical configuration **through the system's own interface** to determine whether it should enforce the expected policy | **No** |
| **Fair** | Reviewing **a copy** of the system's configuration to determine if it should enforce the expected policy | **Yes — the ceiling for this assessment** |
| **Poor** | Statements in documents asserting a control exists, however detailed | Present for all procedural controls |

**Every configuration object examined was a copy** — Terraform source in a repository, not
the deployed resource. Under the CAF's definitions this is **Fair** evidence at best. No
object in this assessment reached Good or Excellent.

## 2. Assessment objects examined

Object types per the CAF: **specification** (policies, plans, procedures, designs),
**mechanism** (functionality in hardware, software, firmware), **activity** (operations,
administration, exercises), **personnel**.

### 2.1 Specifications

| Object | Provides evidence for | Quality |
|--------|----------------------|---------|
| [`docs/security/system-security-plan.md`](../security/system-security-plan.md) | System description, boundary, responsibility model, control narrative | Fair |
| [`docs/security/security-risk-management-plan.md`](../security/security-risk-management-plan.md) | Risk process, treatments, acceptances (IRAP-AR-0015) | Fair |
| [`docs/security/continuous-monitoring-plan.md`](../security/continuous-monitoring-plan.md) | Ongoing assurance process | Fair |
| [`docs/security/incident-response-plan.md`](../security/incident-response-plan.md) | Incident process, severity, playbooks | Fair |
| [`docs/assessment/matrix.yaml`](../assessment/matrix.yaml) | Entity's own control claims and evidence references | Fair |
| [`docs/adr/ADR-0001`](../adr/ADR-0001-organisation-settings-and-email-scheme.md) … [`ADR-0005`](../adr/ADR-0005-region-posture.md) | Decision rationale, risk acceptances | Fair |
| [`docs/assessment/findings/FIND-012.md`](../assessment/findings/FIND-012.md) | Prior finding and remediation (IRAP-AR-0019) | Fair |
| [`README.md`](../../README.md), [`SECURITY.md`](../../SECURITY.md) | System context, repository posture | Fair |

### 2.2 Mechanisms (as declared in source)

| Object | Provides evidence for | Quality |
|--------|----------------------|---------|
| [`live/log-archive/main.tf`](../../live/log-archive/main.tf) | Object Lock, KMS key policy and admin/use split, bucket policy, lifecycle | Fair |
| [`live/log-archive/replica.tf`](../../live/log-archive/replica.tf) | Cross-Region replication, replica retention, replica key policy | Fair |
| [`live/log-archive/securitylake.tf`](../../live/log-archive/securitylake.tf) | OCSF normalisation, SOC subscriber scope | Fair |
| [`live/security-tooling/trail.tf`](../../live/security-tooling/trail.tf) | CloudTrail event selectors, validation, org scope | Fair |
| [`live/security-tooling/config.tf`](../../live/security-tooling/config.tf) | Config aggregation | Fair |
| [`live/security-tooling/findings.tf`](../../live/security-tooling/findings.tf) | Finding routing, page/queue split, SNS topic | Fair |
| [`live/security-tooling/alarms.tf`](../../live/security-tooling/alarms.tf) | Silence alarms, delivery failure, tamper detection | Fair |
| [`live/security-tooling/coverage.tf`](../../live/security-tooling/coverage.tf) | Resource Explorer index underpinning coverage queries | Fair |
| [`live/identity/permission-sets.tf`](../../live/identity/permission-sets.tf) | Permission set definitions, session durations | Fair |
| [`live/identity/assignments.tf`](../../live/identity/assignments.tf) | OU-derived assignments, JIT group treatment | Fair |
| [`live/management/policies/attachments.tf`](../../live/management/policies/attachments.tf) | Policy attachment points, promotion process | Fair |
| [`live/management/policies/*.json`](../../live/management/policies/) | SCP and RCP content — `deny-root`, `region-deny`, `org-perimeter`, `resource-perimeter`, `protect-platform`, `network-denies`, `sandbox-denies` | Fair |
| [`live/management/policies/exceptions.tf`](../../live/management/policies/exceptions.tf) | Plan-time exception reconciliation and expiry assertion | Fair |
| [`live/management/policies/exceptions.yaml`](../../live/management/policies/exceptions.yaml) | The exception register — EXC-001, EXC-002 | Fair |
| [`live/network/firewall.tf`](../../live/network/firewall.tf) | Egress allow-list | Fair |
| [`modules/account-baseline/`](../../modules/account-baseline/) | Birth baseline, Config recorder, session recording, Region opt-in | Fair |
| [`modules/github-oidc/`](../../modules/github-oidc/) | OIDC role model | Fair |
| [`accounts.json`](../../accounts.json) | Account routing | Fair |
| [`.github/workflows/*.yml.disabled`](../../.github/) | Pipeline gate definitions — **committed disabled** | **Poor** |
| [`CODEOWNERS`](../../CODEOWNERS) | Review requirement | Fair |
| [`policy/`](../../policy/) | Policy-as-code checks | Fair |

### 2.3 Activities

| Object | Provides evidence for | Quality |
|--------|----------------------|---------|
| Git commit history | Change control in practice | Fair |
| FIND-012 remediation trail | That prior findings are closed at depth | Fair |

### 2.4 Personnel

**None available.** No interview was conducted with any individual.

## 3. Evidence sought and not obtained (IRAP-AR-0005)

The framework requires that where sufficient evidence cannot be obtained, the limitation,
its impact, and the affected controls are documented.

| Evidence sought | Why needed | Impact | Controls affected |
|---|---|---|---|
| **Evidence objects under `irap/phase-<n>/`** | The entity's matrix references these for most control claims | **None sighted.** Directed assumption A1 treats them as existing. Every *Effective* outcome is conditional on this | Most Layer 2 controls |
| **Live console/API configuration** | To confirm declared configuration is the deployed configuration | Drift undetectable; evidence capped at Fair | All configuration-based controls |
| **Interviews (platform team, CISO, SOC)** | Procedural controls have no other assessable object | 15 controls → **No visibility** | ISM-1685, 1906, 1819, 0140b, 0714, 1071, 0434, 2104–2107, GOV-12, 1173, 0421, 1690, 0140 |
| **Control testing** | To compare actual against expected behaviour | No control confirmed to operate as designed | All |
| **Entra PIM configuration export** | The elevation approval workflow lives here | ISM-1175 **No visibility** despite the entity claiming it met — FIND-T01 | ISM-1175, 1173 |
| **CyberArk configuration and access model** | Holds the root credential | Root custody unassurable — FIND-T06 | ISM-1685, 0873 |
| **Root ceremony records / drill results** | Two-person rule and quarterly drills | **No visibility** — FIND-K04 | ISM-1685, 1819 |
| **AWS IRAP assessment report** | To confirm inherited service and Region scope | Inheritance assessed for logical validity only — FIND-A01, FIND-A02 | ISM-1569, 0467, 1053, 1395 |
| **Third-party assurance artefacts** (Entra, SOC, GitHub, CyberArk) | Supplier assurance under GOV-11 | GOV-11 **Ineffective** — FIND-T04, FIND-T06 | GOV-11, ISM-0873 |
| **SOC contract and agreed source list** | To reconcile subscriber scope with contracted role | FIND-T05 unresolvable from either side | ISM-1906, 1569 |
| **Tenant SSPs** | The platform defers controls to these | Deferral chain unverifiable — FIND-T07 | ISM-1569, 0027 |
| **Brownfield account inventory with data classification** | To determine whether any holds PROTECTED data | The assessment's most consequential unknown — FIND-K07 | ISM-1493, 0140, 1181 |
| **Time synchronisation configuration** | Entity claims ISM-0988 | **Not assessed** — no object found | ISM-0988 |
| **Restoration test records** | ISM-1808 requires backups be tested | **Ineffective** — FIND-K11 | ISM-1808 |

## 4. Objects deliberately not examined

| Not examined | Rationale |
|---|---|
| AWS internal control documentation | Layer 1 — outside this assessment's scope by design |
| Entra ID product internals | Layer 3 — separately assessed product |
| SOC's Sentinel tenant | Provider's own environment, outside the entity's boundary |
| Tenant workload code and data | Separate systems requiring separate assessments |
| Kestrel corporate endpoint management | Outside the boundary; dependency noted as OBS-05 |

## 5. Effect of the evidence position on outcomes

Summarising the relationship between available evidence and the outcomes recorded in
[02 — Cloud Controls Matrix](02-cloud-controls-matrix.md):

| Evidence position | Typical outcome | Count |
|---|---|---|
| Configuration copy examined, meets control intent | **Effective** (conditional on A1/A2) | 21 |
| Configuration copy examined, does not meet intent | **Ineffective** | 3 |
| Only a documented assertion available (Poor evidence) | **No visibility** | 15 |
| Claimed by entity, no supporting object located | **Not assessed** | 4 |
| Entity records a business decision not to implement | **Not implemented** | 1 |
| Control intent met by other means, evidenced | **Alternate control** | 1 |
| Control does not apply | **Not applicable** | 2 |

**The dominant pattern:** where an object existed to examine, the system generally
demonstrated sound design. Where the control's substance was procedural, or resided in a
third-party system, no object existed and the outcome is **No visibility** — which an
authorising officer may treat as ineffective.

That pattern is not a criticism of the entity. It reflects an assessment conducted with only
one of the CAF's three methods available.
