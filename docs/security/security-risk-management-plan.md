# Security Risk Management Plan — Kestrel AWS Landing Zone

| Field | Value |
|-------|-------|
| **System name** | Kestrel AWS Landing Zone (the "platform") |
| **System owner** | Kestrel Digital Pty Ltd |
| **Risk owner** | Chief Information Security Officer |
| **Classification** | PROTECTED |
| **ISM release (pinned)** | June 2026 (`2026.06`) |
| **Document version** | 1.0 |
| **Date** | 26 July 2026 |
| **Review cycle** | Annually, on material change, or on any Extreme/High risk moving band |
| **Status** | Issued for IRAP assessment |
| **Companion documents** | [SSP](system-security-plan.md) · [CMP](continuous-monitoring-plan.md) · [IRP](incident-response-plan.md) · [SSP Annex](../assessment/matrix.yaml) |

> **Provenance.** Kestrel Digital is a fictional scenario; this is a reference
> implementation. Nothing here has been IRAP assessed. See the SSP's provenance note.

---

## 1. Purpose and scope

This plan identifies the security risks to the landing zone, records how each is treated,
and states which **residual** risks the authorising officer accepts. Under the ISM, the
authorising officer must determine the level of residual security risk they will accept
**before** the system is authorised to operate — this document is the basis of that
determination.

Scope is the system boundary defined in [SSP §1.2](system-security-plan.md#12-system-boundary).
Risks belonging to tenant workloads, to Entra ID as an upstream dependency, or to AWS's own
infrastructure are recorded here **only** where Kestrel carries residual exposure.

**The rule this plan holds itself to:** a risk is not treated because a control exists. It
is treated when the control is *implemented, proven by evidence, and monitored*. A control
in code with no evidence object is an untreated risk wearing a treatment's clothes.

## 2. Methodology

Risk is assessed as **likelihood × consequence**, both rated on a five-point scale, on the
model used by the ASD Blueprint SRMP and consistent with ISO 31000.

**Likelihood**

| Rating | Meaning |
|--------|---------|
| Almost certain | Expected in most circumstances; observed in this estate or its peers |
| Likely | Will probably occur |
| Possible | Might occur |
| Unlikely | Could occur but not expected |
| Rare | Only in exceptional circumstances |

**Consequence**

| Rating | Meaning for this system |
|--------|-------------------------|
| Severe | Compromise of PROTECTED data; loss of agency panel standing; mandatory ASD and agency notification |
| Major | Significant compromise of platform integrity or loss of the evidentiary record |
| Moderate | Localised compromise contained by the account boundary; assessable control failure |
| Minor | Degraded control with compensating coverage intact |
| Insignificant | No material security effect |

**Risk matrix**

| Likelihood ↓ / Consequence → | Insignificant | Minor | Moderate | Major | Severe |
|---|---|---|---|---|---|
| **Almost certain** | Medium | Medium | High | Extreme | Extreme |
| **Likely** | Low | Medium | High | High | Extreme |
| **Possible** | Low | Medium | Medium | High | Extreme |
| **Unlikely** | Low | Low | Medium | Medium | High |
| **Rare** | Low | Low | Low | Medium | High |

**Treatment options:** Avoid · Mitigate · Transfer · Accept.

**Tolerance and authority**

| Residual rating | Who may accept | Conditions |
|---|---|---|
| **Extreme** | Not acceptable | Must be treated down before authorisation to operate |
| **High** | CISO, with system owner endorsement | Written acceptance, ADR recorded, expiry date mandatory, quarterly review |
| **Medium** | CISO | Recorded here with owner and review date |
| **Low** | System owner | Recorded; reviewed annually |

Every acceptance of a High residual risk is recorded as a signed ADR in
[`docs/adr/`](../adr/) — an acceptance that lives only in a spreadsheet is not an
acceptance, because nobody can find who agreed to it.

## 3. Threat context

The system's threat actors, in the order they drive design:

1. **Trusted insider with valid credentials** — the *primary* design threat. Kestrel's
   framing throughout is that the danger is not someone changing configuration, it is
   someone **reading the data** through a private path with credentials that are entirely
   legitimate. This is why the organisation trail records network activity and data
   events, not just management events ([SSP §20](system-security-plan.md#20-system-monitoring)).
2. **External actor seeking Australian Government data** — including state-sponsored
   actors, given PROTECTED holdings and the agency panel context.
3. **Supply-chain compromise** — the delivery pipeline, Terraform providers and modules,
   and the managed SOC's access.
4. **Account administrator, acting carelessly or maliciously** — a tenant account admin
   attempting to disable logging, open egress, or reach another tenant.
5. **Opportunistic commodity attack** — credential stuffing, exposed storage, unpatched
   internet-facing services.

Two structural properties shape the whole risk picture: the estate holds PROTECTED data
under agency panel terms with **recovery measured in minutes**, and roughly **60
brownfield accounts** sit in a detective-only posture pending graduation.

## 4. Risk register

Ratings are inherent (before treatment) → residual (after). Controls cite the SSP section
and the code that implements them.

---

### R-01 · Exfiltration of PROTECTED data by an authorised insider

| | |
|---|---|
| **Inherent** | Possible × Severe = **Extreme** |
| **Treatment** | Mitigate |
| **Residual** | Unlikely × Severe = **High** |
| **Owner** | CISO |
| **Acceptance** | CISO, reviewed quarterly |

**Controls.** The `resource-perimeter` SCP prevents Kestrel principals writing to any
resource outside the organisation, closing the path every other control satisfies —
exfiltration to an in-Region attacker bucket. The `org-perimeter` RCP refuses external
principals at S3, KMS, STS, Secrets Manager and SQS even where a resource policy would
grant access. CloudTrail records **data events** on PROTECTED buckets and **network
activity events** on VPC endpoint calls, so the private read path is recorded rather than
assumed. Macie classifies data at rest. All egress traverses one logged, inspected path per
Region. See [SSP §19.3](system-security-plan.md#193-guardrails),
[§20](system-security-plan.md#20-system-monitoring),
[§24](system-security-plan.md#24-networking).

**Why residual is High, not Medium.** Data events are scoped to `kestrel-protected-`
prefixed buckets on cost grounds (R-09), so an insider staging data through a
non-conforming bucket name is detected by Macie and the perimeter policies rather than by
object-level logging. Detection is present; it is not the *same* detection. The
consequence of insider exfiltration of PROTECTED data remains Severe regardless of
control quality, which caps how far this can be driven down.

**Monitoring.** Access-pattern anomalies via GuardDuty; Macie findings; quarterly review of
the data-event scope against the actual bucket-naming population.

---

### R-02 · Loss or tampering of the evidentiary record

| | |
|---|---|
| **Inherent** | Possible × Major = **High** |
| **Treatment** | Mitigate |
| **Residual** | Rare × Major = **Medium** |
| **Owner** | Platform team |

**Controls.** This is the estate's most thoroughly treated risk, because the record is what
makes every other claim assessable. Object Lock in **COMPLIANCE** mode for 7 years — not
GOVERNANCE — so no principal including root can shorten retention. SSE-KMS with a
customer-managed key whose policy **separates administration from use**: no principal holds
both, because an archive encrypted with a key someone can disable is deletable by another
name. CloudTrail log file validation produces digest files proving logs were not altered.
The bucket admits only the trail, Config, flow logs and Resolver logs as writers, each
scoped by `aws:SourceOrgID`. The `protect-platform` SCP makes the machinery undeletable by
account administrators. Cross-Region replication to Melbourne.

**Tamper attempts alarm whether or not they succeed** — the EventBridge rule in
[`live/security-tooling/alarms.tf`](../../live/security-tooling/alarms.tf) covers
`StopLogging`, `DeleteTrail`, `PutObjectRetention`, `StopConfigurationRecorder`, and
critically `ScheduleKeyDeletion`, `DisableKey`, `DisableKeyRotation` and `PutKeyPolicy` —
the KMS path being the one route *around* Object Lock. The deny is the control; the alarm
is the proof someone tried.

**Residual.** The remaining exposure is a sustained compromise of the `log-archive`
account itself combined with the 7-year COMPLIANCE lock being circumvented by AWS — which
requires the provider's own control failure, and is inherited.

---

### R-03 · Evidence plane goes silent without anyone noticing

| | |
|---|---|
| **Inherent** | Likely × Major = **High** |
| **Treatment** | Mitigate |
| **Residual** | Unlikely × Moderate = **Medium** |
| **Owner** | Platform team |

**Why this is its own risk.** A trail that stops writing is a higher-severity condition
than most of what it records, because **everything downstream keeps reporting healthy while
the record quietly stops existing**. Absence of alerts is indistinguishable from absence of
events unless something explicitly watches for silence.

**Controls.** Per-source silence alarms with `treat_missing_data = "breaching"` — silence
produces no datapoints rather than a zero, so treating missing data as breaching is the
entire point. CloudTrail's own `S3DeliveryFailures` metric is alarmed directly, never via a
log query, because the one alarm that must never depend on the trail is the trail-failure
alarm. Connector queue-age and DLQ-depth alarms catch the pipeline backing up rather than
stopping.

**These alarms are Kestrel-only, deliberately.** The provider cannot watch its own feed go
quiet — if the SOC is the thing that failed, an alarm routing through the SOC proves
nothing.

---

### R-04 · Compromise of the management account or root credential

| | |
|---|---|
| **Inherent** | Unlikely × Severe = **High** |
| **Treatment** | Mitigate |
| **Residual** | Rare × Severe = **High** |
| **Owner** | CISO |
| **Acceptance** | CISO — [ADR-0002](../adr/ADR-0002-root-custody.md) |

**Controls.** No guardrail above the management account can protect it, so custody is
procedural and physical. Root credentials live in CyberArk with check-out, approval and
session logging, generated directly into the safe so the password exists in exactly one
place. MFA is two YubiKey 5 FIPS keys, both registered at setup — you cannot do the backup
calmly mid-incident. **Zero access keys**, since a key bypasses MFA. Every root ceremony
runs a **two-person rule**: operator plus witness, evidenced by the checkout log and the
CloudTrail pair. Member-account root credentials are deleted; `deny-root` covers newly
invited accounts before the sweep reaches them. Root use pages at any severity.

**Residual is High and stays High.** Consequence is Severe by definition — root can undo
any control beneath it. Likelihood is driven to Rare, but the product of Rare × Severe is
High under this matrix and is accepted on that basis, not argued down.

**Accepted residual (ADR-0002):** simultaneous loss of both the Sydney and Melbourne safes.
Two cities hold hardware precisely so this is the residual rather than a single-point
failure.

---

### R-05 · Brownfield accounts carry weaker controls than the estate claims

| | |
|---|---|
| **Inherent** | Almost certain × Moderate = **High** |
| **Treatment** | Mitigate (in progress) |
| **Residual** | Likely × Moderate = **High** |
| **Owner** | Platform team |
| **Acceptance** | CISO — **expiry 2027-06-30**, quarterly review |

**The risk.** ~60 accounts were enrolled into the organisation carrying whatever posture
they had grown into. They sit in the `Transitional` OU, which carries **only the org-root
inherited set** — detective posture, not the full preventive layer. Any claim of the form
"the estate enforces X" is false for these accounts until they graduate.

**Controls.** Transitional accounts *do* inherit the org-root layer: `deny-root`,
`region-deny`, `org-perimeter`, `resource-perimeter` and `protect-platform`. They are in
the organisation trail, Config aggregator, GuardDuty and Security Hub from enrolment — they
are **seen**, they are simply not yet **constrained** by the zone layer. Graduation runs the
same baseline a vended account passes at birth: root swept, `ap-southeast-4` opt-in
confirmed, observed usage reconciled, battery green. One path, not two.

**Why residual stays High.** This is honest bookkeeping, not pessimism: the treatment is
*incomplete by design*, proceeding account by account. Rating it Medium before the accounts
have actually graduated would be the exact self-deception this register exists to prevent.
The register carries the expiry; the assessor should expect the number to fall.

**Assessor note.** This is disclosed as a known, bounded, registered gap with a documented
graduation path — not presented as an inconsistency discovered late.

---

### R-06 · Compromise of the delivery pipeline

| | |
|---|---|
| **Inherent** | Possible × Severe = **Extreme** |
| **Treatment** | Mitigate |
| **Residual** | Unlikely × Major = **Medium** |
| **Owner** | Platform team |

**The risk.** The pipeline can change anything in the estate. A compromised pipeline is a
compromised organisation, and it is the path that bypasses the human controls precisely
because it was designed to.

**Controls.** No long-lived credentials anywhere — GitHub authenticates by **OIDC** to
split plan and apply roles. CODEOWNERS review is required on a protected `main`. The checks
workflow holds **no cloud credentials at all** (`terraform fmt`, `validate`, Checkov,
gitleaks), so the untrusted-input stage has nothing to steal. Modules are consumed only from
[`modules/`](../../modules/) pinned by git tag — the estate never pulls third-party code at
apply time. Toolchain is pinned in `versions.tf` with `.terraform.lock.hcl` committed and
verified by `terraform init -lockfile=readonly`. State is per-leaf, so one bad apply cannot
take out the organisation. The `protect-platform` SCP reserves the deployment role name,
closing the squatting hole that its own carve-out opens.

**Residual.** A compromised maintainer account with CODEOWNERS rights, combined with a
merge, remains the live path. Mitigated by MFA on GitHub, branch protection, and the fact
that every apply is recorded in the trail an attacker cannot alter (R-02).

---

### R-07 · Regional outage or unmet recovery obligation

| | |
|---|---|
| **Inherent** | Possible × Major = **High** |
| **Treatment** | Mitigate |
| **Residual** | Unlikely × Moderate = **Medium** |
| **Owner** | Platform team |
| **Decision** | [ADR-0005](../adr/ADR-0005-region-posture.md) |

**Controls.** Both Australian Regions run **active**, each sized so that single-Region
full-estate load is a scaling event rather than a redesign. This deliberately reverses an
earlier pilot-light draft: agency panel terms commit Kestrel to recovery in minutes, and a
pilot light's recovery time is **first measured during the incident**. Two independent
egress estates, one shared edge, and a peering link carrying no default route — a Melbourne
that reaches the internet through Sydney is a pilot light with better marketing.

**Residual.** Roughly double the standing infrastructure spend and two estates to keep
coherent — accepted as the cost of a recovery time that is a measurement rather than a
hope. Data consistency across active-active Regions is a live design problem carried by
each workload.

**Related finding.** FIND-012 — the Melbourne replica's lifecycle carried no expiry rule,
making 7-year retention provable in Sydney but unproven on the copy an assessor would reach
for if Sydney were lost. Fixed in PR #214; the battery gained the replica-retention test it
had lacked.

---

### R-08 · Third-party or supply-chain compromise

| | |
|---|---|
| **Inherent** | Possible × Major = **High** |
| **Treatment** | Mitigate + Transfer |
| **Residual** | Unlikely × Moderate = **Medium** |
| **Owner** | CISO |

**Controls.** AWS and Microsoft are IRAP assessed; their controls are inherited **by
reference** and re-reviewed on each reassessment cycle rather than accepted once at
onboarding — GOV-11 in the June 2026 ISM now requires suppliers be *regularly independently
verified*, and lapse is tracked here. The managed SOC is contracted to Australian-based
operations with vetted personnel, and critically holds a **copy** of security events, never
the record: the evidence plane must outlive the SOC contract. GitHub holds no production
credentials and no data above OFFICIAL.

**Residual.** A compromise at AWS or Entra ID is largely inherited exposure that Kestrel
cannot treat further, only detect and respond to.

---

### R-09 · Detection gaps from cost-driven scope decisions

| | |
|---|---|
| **Inherent** | Likely × Moderate = **High** |
| **Treatment** | Accept, with compensating controls |
| **Residual** | Possible × Moderate = **Medium** |
| **Owner** | Platform team |
| **Acceptance** | CISO, annual review |

**The risk.** Estate-wide S3 data events on hot buckets is the budget flip named in the
Monitoring decisions. The scope was narrowed to write events plus targeted read prefixes on
`kestrel-protected-` buckets. Any PROTECTED data in a non-conforming bucket is outside
object-level logging.

**Why it is accepted rather than mitigated.** Full data-event coverage would consume budget
that currently funds active-active continuity (R-07) and the full detection stack. The
trade is stated rather than hidden.

**Compensating controls.** Macie classification finds PROTECTED data in unexpected places;
the tag policy enforces `DataClassification` on every resource; the perimeter policies
constrain where data can go regardless of whether the read was logged; Config drift
surfaces non-conforming bucket names.

**Review trigger.** Any agency-facing Prod workload, or Macie finding PROTECTED data
outside a conforming bucket, reopens this decision.

---

### R-10 · Excessive standing privilege

| | |
|---|---|
| **Inherent** | Likely × Major = **High** |
| **Treatment** | Mitigate |
| **Residual** | Unlikely × Moderate = **Medium** |
| **Owner** | Platform team |

**Controls.** No IAM users and no long-lived access keys exist anywhere. Every human
identity federates from Entra ID; privileged access is **just-in-time** through Entra PIM —
requested, approved, time-bound, logged. Session durations are the controllable half of the
de-elevation overhang: 1 hour privileged, 4 hours read-only. Four coarse permission sets,
not fourteen.

**Open item.** `WorkloadDeploy` uses `PowerUserAccess`, acceptable only while workloads are
internal. **Flip condition, stated in advance:** it is replaced by a per-workload scoped
policy the moment an agency-facing workload lands in Prod. Tracked in
[SSP §17](system-security-plan.md#17-authentication-hardening).

---

### R-11 · Application control not enforced on managed endpoints

| | |
|---|---|
| **Inherent** | Possible × Moderate = **Medium** |
| **Treatment** | Mitigate (in progress) |
| **Residual** | Possible × Moderate = **Medium** |
| **Owner** | Platform team |
| **Acceptance** | CISO — **expiry 2026-12-01** |
| **Finding** | **FIND-019** (ISM-1553) |

Application control is an Essential Eight mitigation and an open ISM gap, disclosed in the
Annex with owner and expiry rather than omitted. Compensating controls: administrative
access requires a compliant managed device under Conditional Access; no credential exists
that works from an unmanaged endpoint; all instance access is through recorded Session
Manager sessions with no SSH or RDP ingress.

---

### R-12 · Personnel disclosure and insider-recruitment exposure

| | |
|---|---|
| **Inherent** | Possible × Moderate = **Medium** |
| **Treatment** | Mitigate |
| **Residual** | Unlikely × Moderate = **Medium** |
| **Owner** | CISO |

**New in the June 2026 ISM.** ISM-2104 through ISM-2107 restrict personnel from publicly
posting about security clearances, work duties, skills and experience — controls aimed at
the human attack surface and targeted-recruitment risk. GOV-12 additionally requires
*ongoing* personnel suitability assurance rather than point-in-time vetting.

**Controls.** Acceptable-use and social-media policy, acknowledged at onboarding and
annually; suitability re-confirmed on a defined cycle and on role change; vetting status a
precondition of Entra group membership, and group membership the only path to AWS access.

**Stated plainly:** this is a personnel-policy control with **no technical enforcement
point in the platform**. It is recorded as such rather than claimed as implemented in code.

---

### R-13 · AI-assisted development exposing classified data or introducing flaws

| | |
|---|---|
| **Inherent** | Possible × Moderate = **Medium** |
| **Treatment** | Mitigate |
| **Residual** | Unlikely × Minor = **Low** |
| **Owner** | Platform team |

**New in the June 2026 ISM** — seven AI controls covering prevention of classified data
exposure to AI systems, human-approval flags and behavioural baselines.

**Controls.** The controlling facts are structural: this repository contains **no
classified data and no credentials** — every identifier is a documented placeholder — and
no AI tool holds cloud access or can merge a change, because CODEOWNERS approval by a human
is required and the same gates apply to every commit. Secret scanning runs on every pull
request.

**Out of scope.** AI use *within* workloads processing PROTECTED data is a separate system
concern requiring its own assessment against these controls.

---

## 5. Residual risk summary

| Ref | Risk | Inherent | Residual | Treatment | Accepted by |
|-----|------|----------|----------|-----------|-------------|
| R-01 | Insider exfiltration of PROTECTED data | Extreme | **High** | Mitigate | CISO |
| R-02 | Loss or tampering of the evidentiary record | High | Medium | Mitigate | CISO |
| R-03 | Evidence plane silently stops | High | Medium | Mitigate | Platform team |
| R-04 | Management account / root compromise | High | **High** | Mitigate | CISO (ADR-0002) |
| R-05 | Brownfield accounts weaker than claimed | High | **High** | Mitigate (in progress) | CISO — expiry 2027-06-30 |
| R-06 | Delivery pipeline compromise | Extreme | Medium | Mitigate | Platform team |
| R-07 | Regional outage / recovery obligation | High | Medium | Mitigate | CISO (ADR-0005) |
| R-08 | Third-party / supply chain | High | Medium | Mitigate + Transfer | CISO |
| R-09 | Cost-driven detection gaps | High | Medium | Accept + compensate | CISO |
| R-10 | Excessive standing privilege | High | Medium | Mitigate | Platform team |
| R-11 | Application control not enforced | Medium | Medium | Mitigate (in progress) | CISO — expiry 2026-12-01 |
| R-12 | Personnel disclosure exposure | Medium | Medium | Mitigate | CISO |
| R-13 | AI-assisted development | Medium | Low | Mitigate | Platform team |

**Three risks carry a High residual** — R-01, R-04 and R-05. Each requires written CISO
acceptance with system owner endorsement before authorisation to operate, and each is
reviewed quarterly. **No Extreme residual risk exists**, which is the precondition for
authorisation.

R-05 is the only High residual with a *treatment still running*: it falls as accounts
graduate, and the register carries the expiry that forces the review.

## 6. Risk acceptance

The authorising officer accepts the residual risks in §5 on the following basis:

- No residual risk is rated Extreme.
- The three High residuals are each either **irreducible by consequence** (R-01, R-04 —
  compromise of PROTECTED data or of root is Severe regardless of control quality) or
  **bounded with a dated treatment plan** (R-05).
- Every accepted risk has a named owner, a review cadence, and where treatment is
  incomplete, an expiry date.
- Each acceptance is recorded as a signed ADR in [`docs/adr/`](../adr/); an acceptance
  nobody can attribute is not an acceptance.

**Signature block**

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Chief Information Security Officer | | | |
| System Owner | | | |

## 7. Review and maintenance

| Trigger | Action |
|---------|--------|
| **Annual** | Full register review; ratings re-tested against the current ISM release |
| **ISM release change** | Re-pin the release in [`matrix.yaml`](../assessment/matrix.yaml); assess new controls for new risks (as June 2026 produced R-12 and R-13) |
| **Material system change** | Any new zone, new egress path, new third party, or change to the classification handled |
| **Quarterly** | All High residual risks re-reviewed |
| **On expiry** | R-05 (2027-06-30) and R-11 (2026-12-01) must be re-rated or re-accepted, not silently rolled over |
| **On incident** | Any incident rated Sev-1 or Sev-2 triggers review of the risks it touched — see [IRP §8](incident-response-plan.md#8-post-incident-review) |
| **On finding** | A new finding in [`docs/assessment/findings/`](../assessment/findings/) is assessed for whether it changes a residual rating |

Risks move onto this register from four sources: the assessment battery, incident
post-reviews, ISM release changes, and architectural decisions. The register is version
controlled and changes by reviewed pull request, like everything else.
