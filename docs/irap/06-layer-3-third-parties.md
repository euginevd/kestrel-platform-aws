# 06 — Layer 3: Third parties and inter-layer seams

> **NOT AN IRAP ASSESSMENT.** The author is not an ASD-endorsed IRAP assessor. See
> [README](README.md).

**Layer purpose.** Kestrel's security depends materially on entities that are neither AWS
nor Kestrel. This layer assesses whether each is assured and contracted, and — more
importantly — whether the **seam** between that entity and the platform is controlled.

**Overall layer observation.** Individual relationships are reasonably governed. The
weaknesses are concentrated in the seams: one standing credential that contradicts a
headline SSP claim, and a set of assumed-but-unevidenced dependencies. Most controls in
this layer are recorded as **No visibility**, which an authorising officer may treat as
ineffective from a risk perspective.

---

## 1. The entities

| Entity | Role | Criticality | Assurance claimed |
|--------|------|-------------|-------------------|
| **Microsoft Entra ID** | Workforce IdP, MFA, Conditional Access, PIM elevation | **Critical** — sole authentication path | IRAP assessed |
| **Managed SOC** | 24×7 monitoring, triage, first response | High | Contracted; Australian-based, vetted personnel |
| **GitHub** | Source control, CI/CD, deployment trigger | **Critical** — controls the estate | None claimed |
| **CyberArk** | Root credential custody, checkout, session logging | **Critical** — protects the credential above all controls | None claimed |
| **Tenant workload owners** | Application security, data handling, guest OS | High | Own SSPs |
| **NAA disposal authority** | Records retention basis | Low | Referenced |

---

## 2. Microsoft Entra ID

**Assessed outcomes in this area: mixed — see the matrix for per-control outcomes.**

**The dependency is total.** With no IAM users and no long-lived access keys, Entra ID is
the *only* path to human access. Its compromise is the compromise of every account in the
estate — subject only to the break-glass path, which ADR-0002 deliberately keeps outside
Entra precisely for this reason. That circular-dependency avoidance is correct and credited.

**Assessed as sound:**

- Federation via IAM Identity Center with SCIM provisioning
- Group membership sourced from HR, so a departure removes AWS access with no AWS action
- PIM elevation groups hold no standing grant — `sg-aws-*-jit` groups are empty between
  activations
- Conditional Access requiring compliant managed devices
- The SCIM nesting constraint is documented in code: *"must be a cloud-native Entra security
  group, direct members only — SCIM does not flatten nesting"*. This is a real trap and
  catching it in a code comment is good practice

### 2.1 The elevation control is asserted, not evidenced — **FIND-T01**

The most important access control in the system — that privileged access is time-bound,
approved and logged — is implemented in **Entra PIM**, which sits entirely outside the AWS
estate and outside anything in this repository.

The consequence for the assessment is specific: `matrix.yaml` claims ISM-1175 (privileged
access requested, approved, time-bound, logged) with evidence at
`irap/phase-07/elevation-lifecycle-battery.json`. Under assumption A1 that object exists,
but **no configuration, export or attestation of the PIM configuration itself appears
anywhere in the pack**. The AWS side proves the assignment resolves; it cannot prove the
approval workflow, the time-bounding, or the approver set on the Entra side.

Nothing was found covering: who approves elevation, whether self-approval is possible,
maximum activation duration, whether approval is even required or merely justification-on-
activation, or how PIM configuration changes are governed and logged.

**Assessor position.** A privileged-access control implemented in a system outside the
assessment boundary, with no configuration export, is **No visibility** in substance
regardless of what the AWS side shows. This is the most consequential seam in the system.

**Expected.** A PIM configuration export as an evidence object, and PIM configuration change
control brought under the same review discipline as the Terraform.

### 2.2 IdP compromise is not on the risk register — **FIND-T02**

The SRMP's 13 risks include supply-chain compromise (R-08) covering AWS, Microsoft, the SOC
and GitHub collectively at Medium residual.

Given that Entra ID compromise means **total estate compromise**, treating it inside a
general supplier risk understates it. A federated-identity compromise — token forgery,
malicious federated credential, admin consent attack — is a distinct scenario with distinct
detection and response needs, and it is not modelled as one. The IRP has no playbook for it,
where it has playbooks for root compromise and pipeline compromise, which are comparable
scenarios.

**Expected.** A discrete risk for IdP compromise, and an IRP playbook covering detection of
anomalous federated authentication and the response sequence when the IdP itself is suspect.

---

## 3. GitHub

**Assessed outcomes in this area: mixed — see the matrix for per-control outcomes.**

**Assessed as sound.** OIDC only, no long-lived cloud credentials; split plan/apply roles;
the checks stage holds no credentials at all; CODEOWNERS on protected `main`; modules
vendored and pinned by git tag so no third-party code is pulled at apply time; lockfile
verified `-lockfile=readonly`. The supply-chain posture is genuinely good.

### 3.1 A standing credential contradicts the "no long-lived credentials" claim — **FIND-T03**

`live/management/policies/exceptions.yaml`:

```yaml
- id: EXC-002
  scope: "identity: SCIM provisioning token (GitHub Enterprise)"
  control: no-standing-credentials
  narrowed_to: "one PAT scoped to admin:org, held by the provisioning automation"
  reason: "A PAT lifetime policy that expires its own SCIM credential is a self-inflicted outage"
  owner: security-team@kestrel.com.au
  compensating_control: "Scoped to admin:org, visible in the audit log, rotation calendared 90 days before expiry."
  expiry: 2027-07-01
```

A long-lived Personal Access Token scoped to `admin:org` exists.

**The exception register works exactly as designed** — the credential is registered with
owner, reason, compensating control and expiry, reconciled at plan time, and it cannot exist
off-registry. That mechanism deserves credit, and it is why this was findable at all.

**The finding is against the SSP, not the register.** [SSP §17](../security/system-security-plan.md#17-authentication-hardening)
states:

> **No IAM users exist.** There are no long-lived access keys anywhere in the estate

and [SSP §1.4](../security/system-security-plan.md#14-data-flows):

> There is no human path to production infrastructure that bypasses this pipeline

The SSP statement is *literally* true — this is a GitHub PAT, not an AWS IAM key — but it
creates a materially misleading impression. An assessor reading "no long-lived credentials
anywhere in the estate" and later discovering an `admin:org`-scoped PAT would treat the
SSP's precision as suspect, and would then re-examine every other absolute claim in the
document. That reputational effect is worth more than the credential itself.

**On the risk.** `admin:org` on a GitHub Enterprise organisation is a high-privilege scope —
it can manage organisation membership, teams and repository access. Combined with
CODEOWNERS-gated deployment, a compromise of that token is a credible path toward
influencing what merges. The compensating controls (scope limitation, audit log visibility,
calendared rotation) are reasonable but the residual is understated as a routine exception.

**Expected.** The SSP amended to disclose the exception explicitly at §17 rather than only
in the register; the residual risk raised in the SRMP; and a GitHub App with short-lived
installation tokens evaluated as the replacement, since it removes the credential class
entirely rather than managing it.

### 3.2 GitHub carries no assurance requirement — **FIND-T04**

[SSP §4](../security/system-security-plan.md#4-procurement-and-outsourcing) lists GitHub
with the justification:

> Holds no production credentials — OIDC only, no long-lived keys; source is not classified
> above OFFICIAL

Both clauses are now questionable. The first is contradicted by EXC-002. The second is true
of the *source* but not of GitHub's *role*: GitHub is the control plane for a PROTECTED
system. A compromise there does not leak classified source; it changes what runs in
production.

The June 2026 ISM's GOV-11 requires suppliers be *regularly independently verified*. AWS and
Microsoft are IRAP assessed; the SOC is contracted with stated requirements. GitHub has
neither, despite being rated **Critical** in this assessment's own criticality column.

**Expected.** GitHub brought under the supplier assurance regime — SOC 2 Type II or
equivalent reviewed, with the review recorded and re-reviewed on cycle.

---

## 4. The managed SOC

**Assessed outcomes in this area: mixed — see the matrix for per-control outcomes.**

**Assessed as sound and, in one respect, exemplary.** The architectural decision that the
SOC holds *"a copy at most, never the record"* is the right call and is enforced
structurally: the evidence plane is Kestrel's Object-Locked archive, the SOC reads through a
Security Lake subscriber, and revocation at contract end is deleting one resource. The
OCSF-as-contract decision — *"the contract with the provider is a schema, not a product"* —
means the SIEM behind the seam can be replaced without re-plumbing sources. Both are mature
outsourcing decisions.

The decision that the platform's own silence alarms are **Kestrel-only** because *"the
provider cannot watch its own feed go quiet"* is likewise correct.

### 4.1 Subscriber scope versus documented role — **FIND-T05**

Carried from [Layer 2 OBS-04](05-layer-2-kestrel.md#72-security-lake-subscriber-scope--obs-04),
raised here as a finding because it is fundamentally a seam defect.

The SOC subscriber receives `CLOUD_TRAIL_MGMT` only. The SSP, CMP and IRP describe the SOC
as providing 24×7 monitoring and first-line triage of security events, and IRP playbooks
assume SOC visibility of activity that CloudTrail management events do not contain — VPC
flow logs, Route 53 queries, WAF, Security Hub findings.

A SOC seeing only management events cannot triage a network-based intrusion or a data-access
anomaly. Either the subscriber grant is too narrow for the contracted service, or the
documents overstate the SOC's role. **This is the classic seam finding: a responsibility
each side may believe the other covers.**

Note also that the connector queues in `main.tf` deliver S3 notifications for additional
prefixes, so the SOC may receive more via that path — but the two mechanisms are not
reconciled anywhere, and no document states which sources the SOC actually monitors.

**Expected.** A documented, agreed source list — what the SOC receives, what it monitors,
and what it is contractually accountable for detecting — reconciled against both the
subscriber and the connector configuration.

### 4.2 SLA measurement point — Effective

The `securitylake.tf` comment states: *"Everything up to and including the Event Hub is
Kestrel's; everything after is the provider's, and THE SLA MEASURES THAT HANDOFF POINT."*

This is exactly right and unusually well thought through. Most monitoring contracts measure
from ingestion at the provider's end, which makes the consumer's delivery path invisible in
the SLA. Naming the handoff point makes the boundary testable.

### 4.3 SOC personnel and access — No visibility

Contractual requirements for Australian-based operations and vetted personnel are stated.
Verification requires contract review and provider attestation — neither available.
Additionally, the SOC's own access to the subscriber role, and whether SOC-side access is
itself governed by JIT and MFA, is not addressed in the pack.

---

## 5. CyberArk

**Assessed outcome: No visibility.**

CyberArk holds the management account root credential — the credential above every control
in the estate. ADR-0002 describes check-out, approval, session logging, generation directly
into the safe so the password exists in exactly one place, and the two-person rule.

**Nothing in the pack assesses CyberArk itself.** Not its configuration, its own access
controls, who administers it, whether administrators can extract the credential without a
checkout record, or whether the audit log it produces is tamper-evident.

**FIND-T06.** The security of the entire estate reduces, in the last resort, to
the security of this vault. A PAM platform is a high-value target precisely because it holds
the credentials that matter, and its administrators are effectively unconstrained by any
control inside AWS. This is a **critical dependency with no assurance position at all** — it
is not listed in SSP §4's supplier table, carries no assurance claim, and appears in no
risk on the SRMP register.

**Expected.** CyberArk added to the supplier assurance regime; its configuration and access
model documented; the two-person rule's enforceability *within CyberArk* stated; and the
CloudTrail-to-checkout reconciliation of FIND-K04 automated so vault records and AWS records
are provably consistent.

---

## 6. Tenant workload owners

**Assessed outcomes in this area: mixed — see the matrix for per-control outcomes.**

The platform correctly declines to absorb workload responsibilities: guest OS hardening,
application control, patching and application security are pushed to workload owners, and
[SSP §1.5](../security/system-security-plan.md#15-shared-responsibility-cloud-controls-matrix-ism-1569)
tabulates the split. The one-account-per-tenant isolation model in Prod is the right
primitive.

### 6.1 No mechanism verifies tenant SSPs exist — **FIND-T07**

The SSP repeatedly defers controls to "the workload's own SSP". No mechanism was found that:

- Requires a tenant SSP to exist before a workload account is vended
- Verifies the tenant SSP actually covers the deferred controls
- Detects a workload operating without one

The account factory vends from a declared entry in a map. Nothing in
`modules/account-factory/` or the vending path requires evidence of a tenant-side security
plan.

**The risk is the deferral chain terminating nowhere.** The platform says "the workload
covers it", the workload has no SSP, and the control is covered by neither. At PROTECTED,
that gap is the assessor's problem to find and, on this evidence, findable.

**Expected.** Tenant SSP existence as a vending precondition, with the reference recorded in
the factory map entry so the deferral chain is traceable.

### 6.2 Non-Prod data controls — carried from FIND-K03

"Non-Prod has no production data" appears as a stated property of the OU. No technical
control enforces it. Combined with `WorkloadDeploy`/`PowerUserAccess` in Non-Prod, the
combination is weaker than either element suggests alone.

---

## 7. Seam analysis

The most valuable output of a layered assessment: controls where responsibility could fall
between parties.

| # | Seam | Status |
|---|------|--------|
| S1 | **Entra PIM elevation** — AWS proves the assignment, Entra proves the approval. Only the AWS half is evidenced | **FIND-T01** |
| S2 | **SOC monitoring scope** — subscriber grants one source; documents imply many | **FIND-T05** |
| S3 | **GitHub SCIM PAT** — a Layer 3 credential contradicting a Layer 2 claim | **FIND-T03** |
| S4 | **CyberArk custody** — the control protecting root is wholly unassessed | **FIND-T06** |
| S5 | **Tenant SSPs** — platform defers; nothing verifies the recipient exists | **FIND-T07** |
| S6 | **AWS service scope by Region** — inheritance assumed uniform across both Regions | [FIND-A02](04-layer-1-aws.md#22-service-scope-confirmation--find-a02-moderate) |
| S7 | **Corporate IT** — endpoint compliance underpins Conditional Access, which underpins all AWS access. Outside boundary, unassessed | **OBS-05** |
| S8 | **CloudFront edge** — TLS terminates outside Australia under EXC-001 | [OBS-01](04-layer-1-aws.md#24-data-residency--effective-with-one-observation) |

**S7 deserves emphasis.** The access chain is: managed compliant device → Conditional Access
→ Entra → PIM → Identity Center → AWS. The platform assesses from Identity Center rightward.
Everything left of that is declared out of boundary. That is a legitimate scoping decision,
but it means the *first* link in the only path to PROTECTED data is unassessed in this pack,
and the SSP should name the system where it is assessed rather than only naming its owner.

---

## 8. Layer 3 findings summary

| Ref | Finding | Potential impact area |
|-----|---------|----------------------|
| **FIND-T03** | High | GitHub SCIM PAT contradicts the SSP's "no long-lived credentials" claim |
| **FIND-T01** | Moderate | Entra PIM elevation controls asserted but not evidenced |
| **FIND-T02** | Moderate | IdP compromise not modelled as a discrete risk; no IRP playbook |
| **FIND-T04** | Moderate | GitHub carries no supplier assurance despite being control-plane critical |
| **FIND-T05** | Moderate | SOC subscriber scope inconsistent with documented SOC role |
| **FIND-T06** | Moderate | CyberArk wholly unassessed despite holding the root credential |
| **FIND-T07** | Moderate | No mechanism verifies tenant SSPs exist before vending |
| **OBS-05** | Observation | Corporate endpoint management underpins all access but is out of boundary |

## 9. Layer 3 rating

**Observation.** The architectural decisions governing third parties are good — the SOC seam in particular is
better designed than most managed-detection arrangements, and the exception register is what
made the PAT finding possible rather than hidden.

The rating is held down by a consistent pattern: **the controls Kestrel implements are
assessed; the controls Kestrel depends on others to implement are asserted.** PIM approval
workflow, CyberArk custody, endpoint compliance and tenant SSPs are each load-bearing and
each unevidenced. For a system whose strongest characteristic is refusing to claim controls
without evidence, that asymmetry at the boundary is the notable Layer 3 result.
