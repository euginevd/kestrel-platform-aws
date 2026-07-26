# Continuous Monitoring Plan — Kestrel AWS Landing Zone

| Field | Value |
|-------|-------|
| **System name** | Kestrel AWS Landing Zone (the "platform") |
| **Plan owner** | Platform team lead |
| **Accountable officer** | Chief Information Security Officer |
| **Classification** | PROTECTED |
| **ISM release (pinned)** | June 2026 (`2026.06`) |
| **Document version** | 1.0 |
| **Date** | 26 July 2026 |
| **Review cycle** | Annually, and on each ISM release |
| **Status** | Issued for IRAP assessment |
| **Companion documents** | [SSP](system-security-plan.md) · [SRMP](security-risk-management-plan.md) · [IRP](incident-response-plan.md) · [SSP Annex](../assessment/matrix.yaml) |

> **Provenance.** Kestrel Digital is a fictional scenario; this is a reference
> implementation. Nothing here has been IRAP assessed. See the SSP's provenance note.

---

## 1. Purpose

An IRAP assessment is **point-in-time**. This plan describes how Kestrel maintains — and
continuously proves — its security posture between assessments, so that the estate arriving
at the next one is in a known state rather than a hoped-for one.

**The organising idea:** controls emit evidence *by running*. Nothing is produced for the
assessment. A claim with no pre-existing evidence object is a **finding**, not a request to
go make one. This is the same rule that governs the assessment matrix, applied to
day-to-day operation.

The practical consequence is that "continuous monitoring" here is not a reporting activity
bolted onto the platform. It is the platform running normally, with the by-products
collected.

## 2. Scope and objectives

Scope is the system boundary in [SSP §1.2](system-security-plan.md#12-system-boundary).

| Objective | How it is met |
|---|---|
| **Controls stay implemented** | Drift detection, Config rules, CSPM, policy-as-code gates |
| **Evidence stays current** | Evidence objects regenerate on their own cadence, not at assessment time |
| **Coverage stays complete** | Org-wide coverage queries that must return zero gaps |
| **Gaps stay visible** | Findings register with owners and expiries; no silent rollover |
| **New controls get assessed** | ISM release change process (§7) |
| **Posture is reported** | Monthly pack to CISO; quarterly to the risk owner |

## 3. What is monitored, and how often

### 3.1 Continuous — machine speed

| What | Mechanism | Failure route |
|---|---|---|
| Configuration changes across every account and Region | AWS Config recorders, two-speed (continuous/daily), org aggregator | Case queue; drift dashboard |
| Security posture against benchmarks | Security Hub CSPM | Case queue |
| Threat detection | GuardDuty (all accounts, both Regions) | HIGH → page; MED/LOW → case |
| Vulnerabilities | Inspector, continuous scanning | Case queue, tracked to the §5 patch windows |
| Data classification | Macie | Case queue; PROTECTED outside a conforming bucket escalates |
| External access exposure | IAM Access Analyzer | Case queue |
| **Evidence delivery health** | Silence alarms, trail delivery-failure alarm, DLQ depth, queue age | **Page** |
| **Evidence tampering** | EventBridge tamper rule (CloudTrail, S3, Config and KMS events) | **Page**, whether denied or not |
| Root / break-glass use | EventBridge, any severity | **Page** |

### 3.2 Per change — the pipeline gate

Every pull request, before merge:

- `terraform fmt -check` and `terraform validate`
- **Checkov** against the security baseline plus custom tag and naming policies in
  [`policy/`](../../policy/)
- **gitleaks** secret scanning
- `terraform init -lockfile=readonly` — the pinned toolchain is verified, not assumed
- CODEOWNERS review on a protected `main`

The checks workflow runs with **no cloud access and no secrets**. The stage handling
untrusted input has nothing worth stealing, and the pipeline is built so that stays true.

### 3.3 Scheduled

| Cadence | Activity | Output |
|---|---|---|
| **Daily** | Drift detection across every state leaf; coverage query across the organisation | Drift report; coverage must return **zero gaps** |
| **Weekly** | Findings triage — ageing cases, unowned findings, expiring exceptions | Triage record |
| **Monthly** | Posture pack to CISO; Sev-3 incident review in aggregate; brownfield graduation progress | Posture pack |
| **Quarterly** | Break-glass drill (timed, witnessed, locked scenario); High residual risk review; supplier assurance currency check | Drill result; risk review minutes |
| **Six-monthly** | Incident response tabletop; permission set and assignment review | Exercise report; access review record |
| **Annually** | Full assessment battery re-run; SSP, SRMP, CMP and IRP review; recovery test | Assessment pack |
| **On ISM release** | New and changed controls assessed; matrix re-pinned | Updated [`matrix.yaml`](../assessment/matrix.yaml) |

## 4. Drift and coverage

### 4.1 Drift

The estate changes only through a reviewed pull request. Anything that differs from `main`
is, by definition, drift — either an out-of-band change or a control that failed to apply.

Drift detection runs daily against every `live/<account>/<component>` leaf. Detection is
per-leaf because state is per-leaf: a drift report scoped to one component is actionable,
where an estate-wide diff is noise.

| Drift class | Response |
|---|---|
| **Security control drift** (SCP, RCP, key policy, bucket policy, trail, recorder) | Sev-2 — investigate as potential tampering before assuming error |
| **Configuration drift** in a monitored resource | Case; reconcile by pull request |
| **Emergency change** made during an incident | Permitted, must be reconciled to code within **5 business days** (IRP §5) |
| **Unexplained drift** | Treated as an incident until explained, not explained away |

Emergency changes that never return to code are the failure mode this catches: they revert
silently on the next apply, usually at the worst moment, and the control they restored
disappears without an alert.

### 4.2 Coverage

**The success criterion is that a coverage query across the whole organisation returns zero
gaps.** That query needs an authoritative index of *what exists* before it can ask which of
those things are logging — otherwise coverage is checked against the list someone remembered
to maintain, which is exactly the failure the criterion exists to catch.

Resource Explorer aggregates org-wide from the delegated admin
([`live/security-tooling/coverage.tf`](../../live/security-tooling/coverage.tf)), so a newly
vended account appears in the index with no per-account step.

Coverage is asserted across: every account enrolled in the organisation trail; every account
and Region reporting to the Config aggregator; every VPC emitting flow logs; every VPC
emitting Resolver query logs; GuardDuty, Security Hub, Inspector and Macie enabled
everywhere; and both Regions opted in.

**A newly vended account must appear in every one of these within its first day.** A gap
means the baseline did not complete, and the account is not vended until the battery passes.

### 4.3 The ordering that must hold

Config must be recording **before** Security Hub CSPM enables, or CSPM's controls silently
evaluate nothing — the worst failure mode a detective control has, because it reports
healthy while checking nothing. This ordering is forced in code, not preferred, and is
re-verified whenever the detection stack changes.

## 5. Vulnerability and patch monitoring

| Class | Window | Source |
|---|---|---|
| Critical, actively exploited | **48 hours** | Inspector, ASD advisories, vendor notices |
| Critical | **2 weeks** | Inspector |
| High | 1 month | Inspector |
| Moderate and below | Next maintenance cycle | Inspector |

Cadence follows Essential Eight timeframes (ISM-1690). Evidence:
`irap/phase-04/inspector-remediation-windows.json`.

Guest OS and application patching is the workload owner's responsibility; the platform
provides golden AMIs, SSM inventory, the detection, and the escalation when a window is
missed. A missed window is a finding against the workload owner, tracked like any other.

## 6. Evidence lifecycle

Evidence objects live under `s3://kestrel-log-archive/irap/phase-<n>/` and regenerate on
their own cadence.

| Principle | Meaning |
|---|---|
| **Evidence is a by-product** | It is generated by controls running, not by anyone preparing for an assessment |
| **The matrix holds references, never evidence** | So the Object-Locked bucket stays the single source and the matrix stays cheap to diff |
| **Paths must resolve** | CI fails any pull request with an unresolvable evidence path, an unowned gap, or a control absent from the pinned release |
| **Stale evidence is a finding** | An evidence object older than its stated regeneration cadence is treated as absent |

### 6.1 CI reconciliation

The matrix is reconciled automatically. Three conditions fail a pull request:

1. An evidence path that does not resolve under the archive
2. A gap with no owner or no expiry
3. A control referenced that does not exist in the pinned ISM release

This is what keeps the Annex honest between assessments — the document cannot quietly rot,
because the build breaks when it does.

## 7. ISM release change management

The matrix pins one release (`ism_release: 2026.06`). Reconciliation is against **that**
release, so an ISM update is a deliberate, reviewed event rather than a silent redefinition
of compliance.

On each ASD release:

1. **Diff the release** — added, removed, renumbered and reworded controls.
2. **Assess new controls** for applicability at PROTECTED, cloud consumer.
3. **Assess for new risks** — the June 2026 release added the human-attack-surface controls
   (ISM-2104–2107) and seven AI controls, which produced R-12 and R-13 in the
   [SRMP](security-risk-management-plan.md).
4. **Re-pin** the matrix and let CI reconcile; unresolvable rows surface immediately.
5. **Record removals** — ISM-1837 (password non-expiry) was removed in June 2026; a control
   that no longer exists is deleted from the matrix, not left claiming compliance against
   nothing.
6. **Update the SSP** where the narrative changes.

Target: assessed and re-pinned within **one month** of an ASD release.

## 8. Findings and exception management

Findings live in [`docs/assessment/findings/`](../assessment/findings/), one file per
finding, in the assessor's format: severity, control reference, observed versus expected,
disposition.

**Three dispositions, no fourth:**

| Disposition | Requirement |
|---|---|
| **Fixed** | Remediated by pull request, re-tested, **and the battery gained the test it was missing** |
| **Excepted** | On the register with a named owner and a hard expiry |
| **Accepted** | Signed risk acceptance recorded as an ADR in [`docs/adr/`](../adr/) |

**Severity is the assessor's call, not the author's comfort.** The format leaves no clause
for "but the primary is fine" — FIND-012 is the worked example: a retention gap on the
Melbourne replica was rated Moderate on the basis that a retention the DR copy cannot prove
is Moderate whoever wrote the bucket.

**The FIND-012 rule generalises: if the battery had no test for it, the fix adds one.**
That finding existed because nothing asserted the *replica's* retention; the fix PR added
the assertion, re-ran it green, and the next assessment inherits the coverage. A fix that
leaves the same blind spot has not been fixed, it has been patched.

**Expiries do not roll over silently.** An exception reaching expiry is either re-tested and
closed, or re-accepted with a fresh signature and a new date. Both open exceptions —
FIND-019 (2026-12-01) and brownfield graduation (2027-06-30) — are tracked this way.

## 9. Metrics and reporting

Measured continuously, reported monthly to the CISO and quarterly to the risk owner.

| Metric | Target | Why it is measured |
|---|---|---|
| Sample finding → page | **5 minutes** | The routing is only real if it is timed |
| Finding → acknowledgement | Within SLA by severity | `irap/phase-04/finding-to-acknowledgement-timings.json` |
| Coverage query gaps | **Zero** | Any non-zero result is a control not applying somewhere |
| Evidence paths unresolved | **Zero** | Enforced by CI |
| Drift instances unreconciled > 5 days | **Zero** | Catches the emergency change that never came back |
| Exceptions past expiry | **Zero** | Catches silent rollover |
| Critical patch window compliance | 100% | Essential Eight cadence |
| Brownfield accounts graduated | Increasing, tracked to 2027-06-30 | The R-05 treatment, made visible |
| Break-glass drills passed | 4 per year | A failed drill is a finding, not a retry |

Two of these deserve emphasis for the assessor: **coverage gaps** and **evidence paths
unresolved** both have a target of zero and both are machine-checked. They are the metrics
that make the rest of the pack trustworthy, because they fail loudly rather than degrading
quietly.

## 10. Responsibilities

| Activity | Owner |
|---|---|
| Drift and coverage monitoring | Platform team |
| Findings triage and disposition | Platform team, escalating to CISO |
| Evidence lifecycle and CI reconciliation | Platform team |
| First-line detection and triage, 24×7 | Managed SOC |
| Incident response | Per [IRP §2](incident-response-plan.md#2-roles-and-responsibilities) |
| ISM release assessment | Security team |
| Risk register maintenance | CISO |
| Monthly posture pack | Platform team lead → CISO |
| Annual assessment battery | Security team |

## 11. Continuous assessment readiness

The estate re-runs its own assessment battery rather than assembling a pack at assessment
time. The battery raises **unsoftened** findings — severity, control reference, observed
versus expected — and each is dispositioned per §8.

This is what "assessor-ready continuously" means in practice, and it is the reason the
platform can answer an assessor's question by pointing at an object that already exists.
The two rules from [`docs/assessment/README.md`](../assessment/README.md) hold at all times,
not just during an assessment window:

1. **Nothing is produced for the assessment.** A claim with no existing evidence object is a
   finding.
2. **The matrix never contains evidence** — references only, so the Object-Locked archive
   stays the single source.

Arriving at the real assessment **pre-failed and pre-fixed** is the entire objective. A
finding raised by the battery in March and fixed in April is worth more than a clean sheet
that has never been tested.
