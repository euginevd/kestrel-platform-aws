# Incident Response Plan — Kestrel AWS Landing Zone

| Field | Value |
|-------|-------|
| **System name** | Kestrel AWS Landing Zone (the "platform") |
| **Plan owner** | Chief Information Security Officer |
| **Classification** | PROTECTED |
| **ISM release (pinned)** | June 2026 (`2026.06`) |
| **Document version** | 1.0 |
| **Date** | 26 July 2026 |
| **Review cycle** | Annually, after any Sev-1 or Sev-2, and after each exercise |
| **Status** | Issued for IRAP assessment |
| **Companion documents** | [SSP](system-security-plan.md) · [SRMP](security-risk-management-plan.md) · [CMP](continuous-monitoring-plan.md) |

> **Provenance.** Kestrel Digital is a fictional scenario; this is a reference
> implementation. Nothing here has been IRAP assessed. See the SSP's provenance note.

---

## 1. Purpose and scope

This plan defines how Kestrel detects, triages, contains, eradicates, recovers from and
learns from cyber security incidents affecting the landing zone. It covers the system
boundary in [SSP §1.2](system-security-plan.md#12-system-boundary).

**Design principle:** *every finding ends with a person, not a dashboard.* A finding that
only ever lands in a console is one nobody agreed to look at. The routing in §4 exists to
make that true, and to keep the pager credible enough that it is still answered at 3am.

**Incidents in tenant workloads** are the workload owner's to run, with platform support.
Where a workload incident threatens the platform — credential compromise, lateral movement,
evidence-plane impact — this plan takes precedence.

## 2. Roles and responsibilities

| Role | Held by | Responsibility |
|------|---------|----------------|
| **Incident Manager** | On-call platform lead | Owns the incident end to end: declares severity, coordinates, decides containment, calls resolution |
| **CISO** | CISO | Accountable officer; owns external notification decisions and any risk acceptance arising |
| **Platform on-call** | Platform team roster | Technical investigation and containment in AWS |
| **Managed SOC** | Third party, 24×7 | First-line monitoring, triage and escalation against the Sentinel copy |
| **Security tooling operators** | Security team | Evidence collection through Athena and Detective |
| **Communications lead** | Nominated per incident | Agency, customer and internal communications |
| **Legal / Privacy** | Nominated per incident | Notifiable Data Breach assessment, contractual obligations |

**Escalation to root** — where an incident requires management-account root access, the
two-person rule applies without exception: operator plus witness, CyberArk check-out,
evidenced by the checkout log and CloudTrail pair ([ADR-0002](../adr/ADR-0002-root-custody.md)).
An incident is not a reason to skip the witness; it is the reason the witness exists.

## 3. Severity classification

| Severity | Definition | Response | Notification |
|----------|-----------|----------|--------------|
| **Sev-1** | Confirmed or suspected compromise of PROTECTED data; loss of the evidentiary record; management account or root compromise; estate-wide control failure | Immediate, 24×7. Incident Manager engaged within **15 minutes** | CISO immediately; ASD and affected agencies per §7 |
| **Sev-2** | Compromise of a single account or workload; privilege escalation; evidence plane degraded; confirmed intrusion contained by the account boundary | Immediate during business hours, on-call after. Engaged within **1 hour** | CISO within 4 hours; agency if their data is implicated |
| **Sev-3** | Policy violation, control drift with compensating coverage intact, unsuccessful attack with evidence of targeting | Next business day | Internal; reported in the monthly posture pack |
| **Sev-4** | Informational; hygiene findings; unsuccessful commodity activity | Case queue, tracked to closure | Internal only |

**Two conditions page at any severity, by design** — because what makes them urgent is
*what they are*, not how they were scored:

1. **Root or break-glass credential use** — every occurrence, including authorised ones.
   An authorised use that pages is a confirmation; an unauthorised one is a Sev-1.
2. **Evidence-plane tampering** — any attempt to stop the trail, shorten retention, or
   touch the archive CMK, **whether or not it succeeded**. The deny is the control; the
   page is the proof someone tried.

## 4. Detection and routing

Routing is Kestrel's to specify, not left to the provider's defaults. Implemented in
[`live/security-tooling/findings.tf`](../../live/security-tooling/findings.tf) and
[`live/security-tooling/alarms.tf`](../../live/security-tooling/alarms.tf).

| Route | What goes here | Mechanism |
|-------|----------------|-----------|
| **Page now** | Break-glass or root use; Object Lock, trail or KMS-key change; GuardDuty HIGH; CRITICAL/HIGH Security Hub findings; privilege-escalation TTPs | EventBridge → SNS `kestrel-security-page` (SSE-KMS) |
| **Queue as a case** | GuardDuty MEDIUM/LOW, CSPM control failures, Access Analyzer external findings | EventBridge → AWS Security Incident Response case |
| **Dashboard only** | Config drift, cost and volume trend | Neither rule matches these — deliberately |

**The triage split is what stops the pager being ignored.** Everything below HIGH opens a
case rather than waking someone. Target from sample finding to page is **five minutes**,
measured in the assessment battery.

### 4.1 Detecting the absence of signal

Silence is a first-class incident condition. A trail that stops writing is more serious
than most of what it records, because everything downstream keeps reporting healthy while
the record quietly stops existing.

| Alarm | Condition |
|-------|-----------|
| `kestrel-silent-<source>` | No objects delivered for a source in N hours. `treat_missing_data = "breaching"` — silence produces no datapoints, not a zero |
| `kestrel-trail-delivery-failure` | CloudTrail's own `S3DeliveryFailures` metric — never a log query, because the one alarm that must not depend on the trail is the trail-failure alarm |
| `kestrel-queue-age-<source>` | Connector no longer keeping up (>1h oldest message) |
| `kestrel-dlq-<source>` | Anything in a DLQ is data that did not reach Sentinel |

**These alarms are Kestrel-only, deliberately.** The provider cannot watch its own feed go
quiet — if the SOC is the thing that failed, an alarm routing through the SOC proves
nothing.

### 4.2 Evidence tamper detection

The EventBridge tamper rule fires on `StopLogging`, `DeleteTrail`, `UpdateTrail`,
`PutObjectRetention`, `PutBucketObjectLockConfiguration`, `DeleteObjects`,
`StopConfigurationRecorder`, `DeleteDeliveryChannel`, and the KMS path —
`ScheduleKeyDeletion`, `DisableKey`, `DisableKeyRotation`, `PutKeyPolicy`.

The KMS events matter as much as the CloudTrail ones: **the archive CMK is the one path
around Object Lock**, since a locked object encrypted with a disabled key is unreadable,
which is deletion by another name.

## 5. Response process

### Phase 1 — Identification (target: 15 min for Sev-1)

1. Alert reaches the on-call via the page path, or the SOC escalates from Sentinel.
2. On-call acknowledges and performs initial triage: real or false positive?
3. **Declare severity** and open an incident record. If in doubt, declare higher — severity
   is cheaper to lower than to raise late.
4. Incident Manager assigned; for Sev-1, CISO notified immediately.
5. Start the incident log. Every action, decision and timestamp is recorded from this point.

### Phase 2 — Containment

Containment decisions are the Incident Manager's, weighing evidence preservation against
ongoing harm. **Preserve before you purge** — snapshot before terminating, and never
delete the thing that proves what happened.

| Capability | Action | Where |
|---|---|---|
| **Account quarantine** | Move the account to the `Suspended` OU — deny-all SCP applies on attachment | [`live/management/policies/suspended.tf`](../../live/management/policies/suspended.tf) |
| **Session revocation** | Revoke IAM Identity Center sessions; disable the Entra account. Session durations are ≤1h privileged, capping the overhang | [`live/identity/`](../../live/identity/) |
| **Credential invalidation** | No long-lived keys exist to rotate — revocation is federation-side, which is the point |
| **Network isolation** | Withdraw the segment from the Cloud WAN core policy; tighten Network Firewall rules | [`live/network/`](../../live/network/) |
| **Pipeline halt** | Disable the deploy workflow; revoke the OIDC role trust | [`modules/github-oidc/`](../../modules/github-oidc/) |

**Do not disable logging to reduce noise.** It is the single action that converts a
recoverable incident into an unassessable one, and it will itself page.

### Phase 3 — Eradication

1. Determine root cause using Detective's behaviour graphs, Athena over the archive, and
   Config's configuration timeline.
2. Remove the attacker's access: revoke credentials, delete backdoor roles and policies,
   close the entry path.
3. **Fix through the pipeline, not the console.** Emergency console changes are permitted
   only where the pipeline itself is compromised or unavailable, must be witnessed, and
   must be reconciled back into Terraform within **five business days** — an out-of-band fix
   that never returns to code is drift that will silently revert on the next apply.

### Phase 4 — Recovery

1. Restore service from known-good infrastructure-as-code — the estate rebuilds from
   `main`, which is why per-leaf state matters.
2. Verify controls before restoring traffic: re-run the account baseline battery. An
   account is recovered when it **passes the battery**, not when the apply went green.
3. Confirm logging and evidence delivery resumed — check the silence alarms have cleared.
4. Monitor for recurrence at elevated sensitivity for a defined period.
5. Incident Manager formally declares resolution.

### Phase 5 — Post-incident (see §8)

## 6. Evidence handling and forensics

The evidence plane is designed to be forensically sound before an incident, not assembled
during one.

| Property | Why it matters in an incident |
|---|---|
| Object Lock **COMPLIANCE**, 7 years | Logs cannot be altered or deleted by anyone, including root, including an attacker who obtained root |
| CloudTrail log file validation | Digest files prove logs were not altered between write and read |
| KMS admin/use split | The account investigating cannot destroy what it is investigating |
| Independent query path | Athena reads the archive directly — investigation does not depend on the SOC's Sentinel, which may itself be affected |
| Session recordings | Interactive activity on instances is recorded, not reconstructed |

**Chain of custody.** Evidence exported for an incident is written to
`s3://kestrel-log-archive/incidents/<incident-id>/` with the exporting principal, the query
run and the timestamp recorded. The archive is the source; the export is a copy, and the
copy is never the record.

**The SOC holds a copy at most, never the record.** The evidence plane must outlive the SOC
contract — this is a deliberate architectural choice with direct incident-response
consequences: if the SOC relationship ends mid-investigation, Kestrel retains everything.

## 7. Notification and reporting

| Recipient | When | Who decides |
|---|---|---|
| **CISO** | Sev-1 immediately; Sev-2 within 4 hours | Incident Manager |
| **ASD** | Cyber security incidents affecting Australian Government data, per ISM obligations and contract terms | CISO |
| **Affected agency** | Per panel and contract terms — typically immediately on confirmed exposure of their data | CISO |
| **OAIC** | Where an eligible data breach is assessed under the Notifiable Data Breaches scheme | CISO with Legal/Privacy |
| **Affected individuals** | Where required by the NDB scheme | CISO with Legal/Privacy |
| **AWS Support** | Where the incident involves AWS infrastructure or requires provider action | Incident Manager |

**Assessment clock.** Where an incident may constitute an eligible data breach, the
30-day assessment obligation under the Privacy Act starts at the point of awareness. Legal
and Privacy are engaged at declaration for any Sev-1 or Sev-2 touching personal
information — not after the technical work concludes.

Notification content, holding statements and agency contact points are maintained in the
incident response runbook alongside the on-call roster.

## 8. Post-incident review

Every Sev-1 and Sev-2 gets a written review within **10 business days**. Sev-3 incidents
are reviewed in aggregate monthly.

The review covers:

1. **Timeline** — detection, declaration, containment, eradication, recovery, with
   measured intervals against the targets in §3.
2. **Root cause** — technical and process, without stopping at "human error"; the question
   is what made the error possible and what makes it not matter next time.
3. **What detected it, and what should have.** If a human noticed before the platform did,
   that is itself the primary finding.
4. **Control effectiveness** — which controls held, which did not, which were absent.
5. **Actions** — each with an owner and a date, tracked as issues, closed by pull request.

**Feedback loops, all of them mandatory:**

- New or changed risks → [SRMP](security-risk-management-plan.md) register, with re-rating
- Detection gaps → new alarms or rules in `security-tooling`, plus a test in the battery
- Control failures → a finding in [`docs/assessment/findings/`](../assessment/findings/) in
  the assessor's format, dispositioned as fixed, excepted with expiry, or accepted by ADR
- Process failures → this plan, revised

**The FIND-012 precedent governs how findings are written.** That finding recorded a
retention gap the battery had no test for; the fix PR added the missing test, re-ran it
green, and the next assessment inherits the coverage. Severity is the assessor's call, not
the author's comfort — the format leaves no clause to say "but the primary is fine". Post-
incident findings are written the same way.

## 9. Exercises and readiness

| Exercise | Cadence | Scope |
|---|---|---|
| **Break-glass drill** | Quarterly | Root access via CyberArk and YubiKey, two-person rule, against a locked scenario — timed and witnessed ([ADR-0002](../adr/ADR-0002-root-custody.md)) |
| **Tabletop** | Six-monthly | Sev-1 scenario walked through with CISO, platform team and SOC |
| **Detection validation** | Continuous | Sample findings injected; finding-to-page timing measured — `irap/phase-04/finding-to-acknowledgement-timings.json` |
| **Recovery test** | Annually | Rebuild a non-production account from code; verify the battery passes |
| **Silence test** | Per assessment cycle | Confirm the silence alarms fire when a source is deliberately stopped |

Drills are **timed and witnessed against a locked scenario** — a drill whose scenario the
participants wrote that morning measures nothing. Results are recorded as evidence; a
failed drill is a finding, not a retry.

## 10. Scenario playbooks

Condensed decision paths. Full runbooks sit alongside the on-call roster.

### 10.1 Root or break-glass credential used

1. Page fires regardless of severity. Acknowledge within 15 minutes.
2. **Reconcile against the CyberArk checkout log.** Authorised, witnessed, with a matching
   CloudTrail pair → record and close as expected use.
3. No matching checkout → **declare Sev-1 immediately.** The management account is assumed
   compromised.
4. Engage CISO. Rotate root credentials through the two-person ceremony. Review every
   management-account action in the trail for the exposure window.
5. Verify no SCP, RCP, trail or key policy was altered — cross-check against the tamper
   rule's history and the last known-good Terraform state.

### 10.2 Evidence tampering attempted

1. Page fires whether the attempt succeeded or was denied.
2. Identify the principal and determine whether the action was denied by SCP — the
   `protect-platform` policy should have refused it.
3. **A denied attempt is still Sev-2**: someone with credentials tried to destroy the
   record, and that intent is the finding regardless of outcome.
4. Succeeded → **Sev-1.** Verify archive integrity via CloudTrail digest validation and the
   Melbourne replica; determine scope of loss.
5. Suspend the principal's access; treat as insider incident (R-01) until disproven.

### 10.3 Evidence plane goes silent

1. Silence or delivery-failure alarm fires.
2. Distinguish **delivery failure** (bucket policy, KMS key policy, service issue) from
   **source stopped** (trail disabled, recorder stopped, account suspended).
3. A stopped source that nobody changed is a tamper indicator → §10.2.
4. Restore delivery. Determine the gap window precisely and record it — **a gap in the
   record is itself a finding**, and it cannot be backfilled.
5. Reconcile against Config and the Security Lake copy to establish what, if anything, was
   lost.

### 10.4 Workload account compromise

1. Assess blast radius. The account boundary is the primary isolation control — one account
   per tenant in Prod exists for exactly this moment.
2. Contain: move to `Suspended` OU, revoke sessions, snapshot for forensics **before**
   terminating anything.
3. Verify the perimeter held — did `resource-perimeter` prevent writes outbound? Did
   `org-perimeter` prevent external reads? Their behaviour under real attack is the
   highest-value evidence the incident will produce.
4. Investigate lateral movement toward the platform: check for cross-account role
   assumptions in the trail.
5. Rebuild from code rather than cleaning in place. Do not return the account to service
   until the baseline battery passes.

### 10.5 Delivery pipeline compromise

1. **Halt applies immediately** — disable the deploy workflow and revoke OIDC role trust.
2. Review recent merges and applies against CODEOWNERS approvals. An apply with no matching
   approved PR is the smoking gun.
3. Verify the module tags and `.terraform.lock.hcl` were not altered — the pinning exists
   to make substitution visible.
4. Assess state integrity per leaf; state is per-component precisely so this assessment is
   bounded.
5. Rotate GitHub credentials and re-establish OIDC trust before re-enabling. Reconcile
   every resource changed during the exposure window against `main`.

### 10.6 Suspected data exfiltration

1. **Sev-1** where PROTECTED data is implicated.
2. Establish what was accessed using CloudTrail data events, network activity events, flow
   logs and Resolver query logs — the three event categories exist for this question.
3. Establish whether data left the organisation. The `resource-perimeter` SCP should have
   prevented writes to external resources; confirm from the trail rather than assuming.
4. Engage Legal and Privacy for NDB assessment; engage the CISO on agency notification.
5. Note the known scope limit honestly: data events are scoped to `kestrel-protected-`
   prefixed buckets (R-09). Where data sat outside that scope, reconstruct from Macie,
   flow logs and network activity events, and **record the limitation in the incident
   report** rather than presenting partial coverage as complete.
