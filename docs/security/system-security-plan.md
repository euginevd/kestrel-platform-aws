# System Security Plan — Kestrel AWS Landing Zone

| Field | Value |
|-------|-------|
| **System name** | Kestrel AWS Landing Zone (the "platform") |
| **System owner** | Kestrel Digital Pty Ltd |
| **Authorising officer** | Chief Information Security Officer |
| **Classification** | **PROTECTED** (Australian Government data), with OFFICIAL and OFFICIAL: Sensitive workloads inheriting the same controls |
| **Dissemination limiting markers** | Applicable per-tenant; carried as resource tag `DataClassification` |
| **ISM release (pinned)** | **June 2026** (`ism_release: 2026.06`, [`docs/assessment/matrix.yaml`](../assessment/matrix.yaml)) |
| **Cloud posture** | Cloud consumer on AWS; `ap-southeast-2` (Sydney) and `ap-southeast-4` (Melbourne) only |
| **Document version** | 1.0 |
| **Date** | 26 July 2026 |
| **Review cycle** | Annually, or on material change to the system (ISM-0047) |
| **Status** | Issued for IRAP assessment |

> **Scope note for the assessor.** This SSP describes the **landing zone** — the
> multi-account foundation, its guardrails, identity, logging, network and delivery
> pipeline. Tenant workloads deployed *into* the landing zone are separate systems with
> their own SSPs; this document states precisely what they **inherit** and what remains
> **their** responsibility (see §1.5).

> **Provenance.** Kestrel Digital is a **fictional scenario** and this platform is a
> reference implementation. Every identifier in the cited code is a documented
> placeholder (org ID `o-kestrel00id`, account IDs of the form `123456789012`, the
> `kestrel.com.au` domain). **Nothing described here has been IRAP assessed.** The
> control-to-evidence work in [`docs/assessment/`](../assessment/) is a *self-assessment
> on IRAP methodology*, which is not an IRAP assessment — that requires an ASD-endorsed
> registered assessor. This document is written to be assessable, not to assert an
> assessment outcome.

---

## How to read this document

This SSP follows the chapter structure of **ASD's Blueprint for Secure Cloud System
Security Plan**, which mirrors the ISM's guidelines. It is the **narrative** artefact:
it describes architecture, data flows, the access model, cryptography and response
procedures in prose.

It deliberately does **not** restate control-by-control compliance. That belongs in two
companion artefacts:

| Artefact | What it holds | Where |
|----------|---------------|-------|
| **SSP (this document)** | Narrative: what the system is, how it is built, how it is run | `docs/security/system-security-plan.md` |
| **SSP Annex** | One row per applicable ISM control: implemented / partial / not applicable, with justification | [`docs/assessment/matrix.yaml`](../assessment/matrix.yaml) — the control-to-evidence matrix, machine-readable, on the ASD SSP-A template model |
| **Cloud Controls Matrix** | Provider-versus-consumer responsibility split (ISM-1569) | §1.5 below, and the inherited-controls reference `aws-irap-2026` |

Two rules govern the evidence in the Annex, and they hold for this SSP too:

1. **Nothing is produced for the assessment.** A claim with no pre-existing evidence
   object is a *finding*, not a request to go generate one.
2. **The matrix never contains evidence** — only references that resolve under
   `s3://kestrel-log-archive/irap/phase-<n>/`, so the Object-Locked archive stays the
   single source of truth.

Related documents:

- **Security Risk Management Plan (SRMP)** — risk assessment and treatment
- **Continuous Monitoring Plan** — §20, and the drift/detective battery
- **Incident Response Plan** — §3
- **Architecture Decision Records** — [`docs/adr/`](../adr/) — the load-bearing decisions
- **Findings register** — [`docs/assessment/findings/`](../assessment/findings/)

---

## 1. Overview

### 1.1 System purpose

Kestrel Digital is a Sydney-based SaaS scale-up hosting Australian Government data up to
**PROTECTED**. The landing zone is the multi-account AWS foundation every Kestrel
workload deploys into. Its purpose is that a new workload **inherits** identity,
guardrails, logging and networking on the day it is created, rather than having security
bolted on afterwards.

Four properties define the system:

- **Secure by default** — guardrails are inherited at account birth, not applied by a
  later hardening pass.
- **Sovereign by default** — Australian Regions only, provable from configuration rather
  than asserted by policy.
- **Entirely as code** — the organisation changes only through a reviewed pull request.
- **Continuously assessable** — controls emit evidence by running, mapped to the ISM.

### 1.2 System boundary

**In boundary:**

- The AWS Organization (`o-kestrel00id`) and its full OU tree
- The four core accounts: `management`, `log-archive`, `security-tooling`,
  `shared-services`
- Organisation-wide policy instruments: SCPs, RCPs, declarative policies, tag policies
- The identity plane: IAM Identity Center, federated from Microsoft Entra ID
- The network fabric: AWS Cloud WAN, IPAM, inspection VPCs, Network Firewall, egress
- The logging and evidence plane: organisation CloudTrail, AWS Config, Security Lake,
  the Object-Locked S3 archive
- The delivery pipeline: this Git repository, GitHub Actions with OIDC, Terraform state
  in an in-boundary S3 bucket

**Out of boundary (interfaces, not components):**

- Tenant workload application code and data planes — separate systems, separate SSPs
- Microsoft Entra ID as the identity provider — an assessed upstream dependency
- The managed SOC's Microsoft Sentinel tenant — receives a **copy** of security events;
  it is the *operations* plane, never the record
- AWS's own infrastructure and managed-service internals — inherited, evidenced by AWS's
  IRAP assessment (`aws-irap-2026`)

### 1.3 The estate, grouped by policy

The OU tree is aligned to the AWS Security Reference Architecture and grouped by
**policy**, not org chart — an account's OU determines what it inherits.

```text
Root (Kestrel Organisation)
├── Security             # log archive + security tooling — the delegated admin
├── Infrastructure       # network core, shared services, state backend
├── Workloads
│   ├── Prod             # customer-facing, PROTECTED data — one account per tenant
│   └── Non-Prod         # dev, test, staging — no production data
├── Sandbox              # time-boxed experimentation
├── Transitional         # ~60 brownfield accounts, detective-only until they graduate
└── Suspended            # quarantine — deny-all
```

**Transitional is material to the assessment.** Roughly 60 pre-existing ("brownfield")
accounts were enrolled into the organisation and sit in an OU that carries **only the
org-root inherited controls** — detective posture, not the full preventive set. They
graduate one at a time by passing the same baseline a newly vended account passes.
Assessors should treat Transitional as a **known, bounded, registered gap** with a
documented graduation path, not as an inconsistency. See
[`live/management/organisation/transitional.tf`](../../live/management/organisation/transitional.tf)
and §19.4.

Account-to-ID routing is declared in [`accounts.json`](../../accounts.json); workload
accounts exist only as account-factory map entries, with their infrastructure in their
own repositories.

### 1.4 Data flows

**Log and evidence flow (the record):**

```text
every account in the org
  ├── CloudTrail (management + data + network activity events)   ─┐
  ├── AWS Config (configuration items, two-speed recording)       │
  ├── VPC Flow Logs                                               ├─► s3://kestrel-org-cloudtrail-ap-southeast-2
  ├── Route 53 Resolver query logs                                │    (log-archive account, Object Lock COMPLIANCE 7y,
  └── Session Manager session recordings                         ─┘     SSE-KMS with a customer-managed key)
                                                                          │
                                    ┌─────────────────────────────────────┤
                                    ▼                                     ▼
                    Amazon Security Lake (OCSF)              Athena (query, security-tooling)
                                    │                                     │
                                    ▼                                     ▼
                    SQS connector queues ──► SOC's Sentinel      IRAP evidence exports
                       (operations plane, a copy)                irap/phase-<n>/
                                                                          │
                                    ┌─────────────────────────────────────┘
                                    ▼
                       Cross-Region replica (ap-southeast-4)
```

The archive is written **once** and read twice — the SOC connector and Athena both read
the same object, rather than a second pipeline nobody reconciles.

**Administrative access flow:**

```text
Kestrel staff ──► Entra ID (MFA, Conditional Access)
                    │
                    ├── Entra PIM: just-in-time elevation, time-bound, approved
                    ▼
              IAM Identity Center (permission sets, 1h privileged / 4h read-only)
                    ▼
              target AWS account ──► session logged to CloudTrail
                                     interactive sessions recorded via Session Manager
```

**Deployment flow:**

```text
pull request ──► CODEOWNERS review ──► checks (fmt, validate, Checkov, gitleaks — no cloud creds)
                                          │
                                          ▼
                                     merge to main
                                          ▼
                          GitHub Actions ──OIDC──► KestrelDeploy role in target account
                                          ▼
                             terraform apply (state in in-boundary S3)
```

There is no human path to production infrastructure that bypasses this pipeline; the
`protect-platform` SCP makes the pipeline's own machinery undeletable by account
administrators.

### 1.5 Shared responsibility (Cloud Controls Matrix, ISM-1569)

| Layer | Responsible | Evidence |
|-------|-------------|----------|
| Physical facilities, hypervisor, managed-service internals | **AWS** | AWS IRAP assessment (`aws-irap-2026`); AWS is on the ASD Certified Cloud Services List equivalent / assessed for PROTECTED in Australian Regions |
| Organisation structure, OUs, policy instruments | **Kestrel (platform team)** | [`live/management/`](../../live/management/) |
| Identity, federation, elevation | **Kestrel (platform team)** + Entra ID | [`live/identity/`](../../live/identity/) |
| Network fabric, egress, inspection | **Kestrel (platform team)** | [`live/network/`](../../live/network/) |
| Logging, evidence retention | **Kestrel (platform team)** | [`live/log-archive/`](../../live/log-archive/), [`live/security-tooling/`](../../live/security-tooling/) |
| Detection, triage, response | **Kestrel** + managed SOC | §3, §20 |
| Workload application security, data handling within the tenant | **Tenant workload owner** | The workload's own SSP |
| Guest OS patching, application control on workload instances | **Tenant workload owner** | §14, §15 — see FIND-019 |

Controls Kestrel **inherits** from AWS are listed by reference in the Annex under
`inherited: aws-irap-2026` and are not re-evidenced here. Kestrel does not claim a
control merely because AWS offers a capability — the claim is that the capability is
**configured and proven** in this estate.

---

## 2. Cyber security roles

| Role | Responsibility |
|------|----------------|
| **CISO** | Accountable for the security of the system; owns residual risk acceptance and the standing continuity obligation |
| **System owner** | Accountable for the platform's authorisation to operate |
| **Platform team** | Builds and operates the landing zone; owns every `live/` and `modules/` change |
| **Security tooling operators** | Operate detection tooling in the `security-tooling` account; hold *use* privilege on the evidence plane, never *management* privilege |
| **Managed SOC (third party)** | 24×7 monitoring, triage and first response against the Sentinel copy of security events |
| **CODEOWNERS** | Named reviewers whose approval is required before any change merges — [`CODEOWNERS`](../../CODEOWNERS) |

Personnel changes flow from the HR system into Entra ID; group membership is the sole
source of AWS access (§17), so a departure removes access without a separate AWS action.

**June 2026 ISM note.** The GOVERN function expanded from 7 to 14 principles in this
release. GOV-11 (supplier cyber security assurance, now requiring *regularly
independently verified* suppliers) applies directly to AWS, Microsoft and the managed SOC
— see §4. GOV-12 (personnel suitability assurance, requiring *ongoing* assurance) applies
to §7.

## 3. Cyber security incidents

**Detection.** GuardDuty, Security Hub CSPM, Inspector, Macie and AWS Config rules emit
findings; EventBridge routes them by severity
([`live/security-tooling/findings.tf`](../../live/security-tooling/findings.tf)). CloudWatch
alarms cover the platform's own integrity events — notably any attempt to disable or
schedule deletion of the archive's KMS key
([`live/security-tooling/alarms.tf`](../../live/security-tooling/alarms.tf)).

**Triage.** Findings reach the managed SOC through Security Lake's OCSF-normalised feed
and the SQS connector queues. The SOC works against Sentinel; Kestrel retains the record
in the Object-Locked archive so an incident can be reconstructed after the SOC contract
ends.

**Response.** The Incident Response Plan defines severity, timeframes and escalation. The
platform provides three response capabilities:

- **Quarantine** — an account can be moved to the `Suspended` OU, which carries a
  deny-all SCP ([`live/management/policies/suspended.tf`](../../live/management/policies/suspended.tf))
- **Forensic readiness** — Detective is enabled estate-wide
  ([`live/security-tooling/detective.tf`](../../live/security-tooling/detective.tf)); the
  archive is immutable and independently queryable through Athena
- **Break-glass** — root-plus-YubiKey, deliberately outside Entra ID, so an IdP outage
  cannot lock out the estate that would fix it (ADR-0002)

**Reporting.** Cyber security incidents affecting Australian Government data are reported
to ASD and to the affected agency in accordance with contractual and ISM obligations.

**Evidence.** Finding-to-acknowledgement timings are exported to
`irap/phase-04/finding-to-acknowledgement-timings.json` (ISM-1906).

## 4. Procurement and outsourcing

| Supplier | Service | Assurance |
|----------|---------|-----------|
| **AWS** | IaaS/PaaS, Australian Regions | IRAP assessed for PROTECTED; assessment report reviewed and its controls inherited by reference |
| **Microsoft** | Entra ID (identity provider) | IRAP assessed; the workforce IdP decision is ADR-0004 |
| **Managed SOC** | 24×7 monitoring | Contracted; personnel vetting and Australian-based operations required by contract |
| **GitHub** | Source control and CI | Holds no production credentials — OIDC only, no long-lived keys; source is not classified above OFFICIAL |

Per GOV-11 (new emphasis in June 2026), supplier assurance is **regularly and
independently verified** rather than accepted once at onboarding: assessment reports are
re-reviewed on each supplier's reassessment cycle, and lapse is tracked on the risk
register.

**Data sovereignty.** All Australian Government data resides in `ap-southeast-2` and
`ap-southeast-4`. The `region-deny` SCP enforces this at the organisation root
([`live/management/policies/attachments.tf`](../../live/management/policies/attachments.tf)),
with its service carve-out list vendored from AWS's maintained Control Tower list rather
than hand-written — an omission in that list is an outage, not a security gap.

## 5. Security documentation

This SSP, the SSP Annex ([`matrix.yaml`](../assessment/matrix.yaml)), the SRMP, the
Continuous Monitoring Plan and the Incident Response Plan constitute the system's security
documentation. All are version-controlled in this repository and change only by reviewed
pull request — documentation is **docs-as-code**, with the same gate as infrastructure.

Architectural decisions are recorded as ADRs in [`docs/adr/`](../adr/) and are never
deleted:

| ADR | Decision |
|-----|----------|
| [ADR-0001](../adr/ADR-0001-organisation-settings-and-email-scheme.md) | Organisation settings and email scheme |
| [ADR-0002](../adr/ADR-0002-root-custody.md) | Root credential custody |
| [ADR-0003](../adr/ADR-0003-engine-and-state.md) | Terraform-native on Organizations; self-managed in-boundary S3 state |
| [ADR-0004](../adr/ADR-0004-workforce-identity-provider.md) | Entra ID as workforce IdP |
| [ADR-0005](../adr/ADR-0005-region-posture.md) | Both Australian Regions active |

Risk acceptances are signed and recorded as ADRs; exceptions carry an owner and an expiry
and appear in the Annex as a `gap`, never as a blank.

## 6. Physical security

Inherited from AWS for all cloud infrastructure (`aws-irap-2026`); Kestrel operates no
data centre.

Kestrel-controlled physical security covers the **root MFA hardware**: two YubiKey 5 FIPS
keys, primary in the Sydney HQ safe and backup in Melbourne, both registered at setup
(ADR-0002). Two cities holding hardware is deliberate; the simultaneous loss of both
safes is the accepted residual risk.

Corporate offices and endpoint physical security are covered by Kestrel's enterprise
security documentation, outside this system's boundary.

## 7. Personnel security

Personnel with administrative access to PROTECTED systems are vetted to the level
required by the engaging agency, with security clearances obtained through AGSVA where
the agency requires them. Vetting status is a precondition of Entra group membership, and
group membership is the only path to AWS access.

**June 2026 additions.** GOV-12 requires *ongoing* personnel suitability assurance rather
than point-in-time vetting; Kestrel re-confirms suitability on a defined cycle and on role
change. ISM-2104 through ISM-2107 (new in June 2026) restrict personnel from posting
publicly about security clearances, work duties, skills and experience — these are
addressed in Kestrel's acceptable-use and social-media policy, with acknowledgement
captured at onboarding and annually. This is a **personnel-policy control with no
technical enforcement point in the platform**, and is stated as such rather than claimed
as implemented in code.

Privileged access requires a separate privileged identity (ISM-1507) — satisfied by JIT
elevation through Entra PIM rather than standing privilege (§17, §19.2).

## 8. Communication infrastructure

Inherited from AWS. Kestrel operates no physical communications infrastructure; all
inter-account and inter-Region connectivity is AWS-managed backbone, never the public
internet.

## 9. Communications systems

Not applicable — the system carries no telephony or dedicated communications system.
Administrative and application traffic is covered by §24 (Networking) and §25
(Cryptography).

## 10. Enterprise mobility

Administrative access from mobile and remote endpoints is governed by Entra ID
Conditional Access: compliant, managed devices with MFA. No AWS console or API access is
possible from an unmanaged device, because there is no credential to use from one — there
are no IAM users and no long-lived access keys (§17).

Device compliance policy is owned by Kestrel's enterprise IT and is an interface to this
system, not a component of it.

## 11. Evaluated products

The system uses no product requiring Common Criteria evaluation. Cryptographic modules
are AWS KMS (FIPS 140-3 validated in the Australian Regions) and YubiKey 5 FIPS series
hardware tokens for root MFA (ADR-0002).

## 12. ICT equipment

Inherited from AWS for all compute, storage and network equipment, including
sanitisation and destruction on decommission.

Kestrel-controlled ICT equipment is limited to administrative endpoints (§10) and the
root MFA hardware (§6).

## 13. Media

Inherited from AWS for physical media handling and destruction.

Logical media sanitisation is a Kestrel responsibility. Two retention regimes apply, and
the distinction is deliberate:

| Store | Object Lock mode | Retention | Why |
|-------|------------------|-----------|-----|
| Log archive | **COMPLIANCE** | 7 years | Records-schedule retention; nobody, including root, can shorten it |
| Terraform state | **GOVERNANCE** | 30 days | State can hold a provider-generated secret and must stay purgeable |

Account decommissioning is as deliberate as vending; the account factory
([`modules/account-factory/`](../../modules/account-factory/)) treats closure as an
explicit declared act, not a deletion.

## 14. Operating system hardening

The landing zone itself runs no persistent operating systems — it is composed of managed
services.

For workload instances, the platform provides golden AMIs and SSM inventory from
`shared-services`, and Inspector runs estate-wide for vulnerability detection
([`live/security-tooling/`](../../live/security-tooling/)). **Guest OS hardening and
patching are the workload owner's responsibility**; the platform provides the mechanism
and the detection, and reports non-compliance as a finding.

Interactive access to instances is through Session Manager only — no SSH or RDP ingress
exists — and sessions are recorded to the log archive
([`modules/account-baseline/sessions.tf`](../../modules/account-baseline/sessions.tf)).
Session recordings are the one platform log source written by an IAM principal rather
than a service, constrained by `aws:PrincipalOrgID` and confined to the
`session-recordings/` prefix.

Patch cadence follows Essential Eight timeframes: critical patches within two weeks, and
within 48 hours where a vulnerability is being actively exploited (ISM-1690); evidence at
`irap/phase-04/inspector-remediation-windows.json`.

## 15. User application hardening

Applies to Kestrel's corporate endpoint fleet, governed by enterprise IT and outside this
system's boundary.

**Known gap — application control (ISM-1553).** Application control is not yet enforced on
all managed endpoints. This is recorded in the Annex as an open gap with owner
`platform-team` and expiry `2026-12-01`, tracked as **FIND-019**. It is disclosed here
rather than omitted, in keeping with the rule that a claim without evidence is a finding.

## 16. Server application hardening

Server applications belong to tenant workloads. The platform's contribution is
architectural: no workload account has its own route to the internet (the
`network-denies` SCP denies internet gateways in both IPv4 and IPv6 and denies public
addressing), so a misconfigured server application is not directly reachable.

Default VPCs are deleted in both Regions at account birth, and the posture setting
preventing their recreation is applied by the baseline
([`modules/account-baseline/main.tf`](../../modules/account-baseline/main.tf)) — a
workload account's network is the declared tier or nothing.

## 17. Authentication hardening

**No IAM users exist.** There are no long-lived access keys anywhere in the estate; the
last were deleted as part of the Identity phase. Every human identity is federated from
Entra ID into IAM Identity Center (ADR-0004), and every machine identity is a role
assumed through OIDC ([`modules/github-oidc/`](../../modules/github-oidc/)).

**Multi-factor authentication** is enforced at Entra ID for all users, phishing-resistant
for privileged roles.

**Permission sets** are deliberately coarse — four, not fourteen — with session durations
chosen as the controllable half of the de-elevation overhang
([`live/identity/permission-sets.tf`](../../live/identity/permission-sets.tf)):

| Permission set | Session | Scope |
|----------------|---------|-------|
| `PlatformAdmin` | 1 hour | `AdministratorAccess` |
| `WorkloadDeploy` | 1 hour | `PowerUserAccess` |
| `PlatformReadOnly` | 4 hours | `ReadOnlyAccess` |
| `SecurityAudit` | 4 hours | `SecurityAudit` |

`WorkloadDeploy` uses `PowerUserAccess`, which is acceptable only while workloads are
internal; it is replaced by a per-workload scoped policy the moment an agency-facing
workload lands in Prod. This is stated as a **time-bounded posture with a named flip
condition**, not as a permanent design.

**Root.** Member-account root credentials are deleted. Management-account root lives in
CyberArk with check-out, approval and session logging; MFA is hardware (ADR-0002), access
keys are zero, and every root ceremony runs a **two-person rule** — operator plus witness,
evidenced by the checkout log and the CloudTrail pair. The `deny-root` SCP at the
organisation root covers newly invited accounts before the credential sweep reaches them.

**Privileged access is just-in-time**: requested, approved, time-bound and logged through
Entra PIM. Evidence at `irap/phase-07/elevation-lifecycle-battery.json` (ISM-1175) and
`irap/phase-07/standing-privilege-enumeration.json` (ISM-1507).

## 18. Virtualisation hardening

Hypervisor and virtualisation-layer hardening is inherited from AWS (Nitro System),
evidenced by AWS's IRAP assessment.

Tenant isolation at Kestrel's layer is achieved by **account boundary**, not by
in-account segmentation: one account per tenant in Prod, so the strongest isolation
primitive AWS offers is the one carrying tenant separation.

## 19. System management

### 19.1 Change management

The organisation changes only through a reviewed pull request. Every change passes:

1. **CODEOWNERS review** — required approval on a protected `main`
2. **Automated checks** — `terraform fmt`, `terraform validate`, Checkov against the
   baseline and custom tag/naming policies in [`policy/`](../../policy/), and gitleaks —
   run with **no cloud access and no secrets**
3. **Plan and apply** through OIDC-assumed roles, with plan and apply as split roles

Evidence: `irap/phase-02/pipeline-end-to-end-run.json` (ISM-1526).

**State integrity.** Each `live/<account>/<component>` leaf is one root config with its
own state key — never one estate-wide state, so a single bad apply cannot take out the
organisation. Every leaf pins its toolchain in an identical `versions.tf` and commits
`.terraform.lock.hcl`; the pipeline verifies it with `terraform init -lockfile=readonly`.
Modules are consumed only from [`modules/`](../../modules/), pinned by git tag — the
estate never pulls third-party code at apply time.

### 19.2 Privileged access management

Covered in §17. The principle: **management privilege and usage privilege are never held
by the same principal.** The account that can read all logs is not the account that runs
the security tools, and neither is the organisation root.

### 19.3 Guardrails

Four policy instruments, attached to **OUs, never accounts**, so an account vended
tomorrow inherits enforcement before its first resource exists. All are targeted denies
on top of `FullAWSAccess`, never allow-lists
([`live/management/policies/`](../../live/management/policies/)):

| Policy | Type | Effect |
|--------|------|--------|
| `deny-root` | SCP | Root as depth, covering accounts before the credential sweep |
| `region-deny` | SCP | Australian Regions only |
| `org-perimeter` | RCP | External principals refused by S3, KMS, STS, Secrets Manager and SQS even where a resource policy would grant access |
| `resource-perimeter` | SCP | Kestrel principals cannot write to resources outside the organisation — closes exfiltration to an in-Region attacker bucket |
| `protect-platform` | SCP | The machinery producing every proof is not deletable by account administrators |
| `network-denies` | SCP (Workloads) | No own way out (v4 and v6), no public addresses, VPCs from IPAM only |
| `sandbox-denies` | SCP (Sandbox) | Bounded by service and blast radius |

The data perimeter is closed in three directions: identity, resource and network.

**Promotion is process, enforced by review.** Every policy candidate passes a canary
battery in `Policy-Staging`, then Non-Prod precedes Prod by a working day; root-attached
policies take a three-PR path, because a root attachment lands on Prod the instant it
applies.

Exceptions are **narrowed denies** registered in `exceptions.yaml`, never bypasses of the
zone layer.

### 19.4 Brownfield graduation

The ~60 Transitional accounts graduate by meeting the same criteria a vended account meets
at birth: member root swept, `ap-southeast-4` opt-in confirmed, observed usage reconciled,
and the account-baseline battery passed. There is **one path, not two** — the birth
baseline *is* the graduation checklist
([`modules/account-baseline/`](../../modules/account-baseline/)). Every baseline step is
idempotent: a failed vend is finished by re-running the apply, never by hand, and an
account is vended when it **passes the battery**, not when the pipeline went green once.

### 19.5 Backup and continuity

Both Australian Regions are **active**, sized so that single-Region full-estate load is a
scaling event rather than a redesign (ADR-0005). This reverses an earlier pilot-light
draft: the agency panel terms commit Kestrel to recovery measured in minutes, and a
pilot light's recovery time is first measured during the incident.

The network makes the claim true — two independent egress estates, one shared edge, and a
peering link carrying no default route. A Melbourne that reaches the internet through
Sydney is a pilot light with better marketing.

The log archive replicates cross-Region to `ap-southeast-4`
([`live/log-archive/replica.tf`](../../live/log-archive/replica.tf)). **FIND-012** — the
Melbourne replica's lifecycle rule carried no expiry, making 7-year retention provable in
Sydney but unproven on the copy an assessor would reach for if Sydney were lost — was
raised at Moderate, fixed in PR #214, and the battery gained the replica-retention test it
had been missing.

## 20. System monitoring

The evidence plane is the heart of the system's assessability.

**The sink.** `s3://kestrel-org-cloudtrail-ap-southeast-2` in the `log-archive` account
([`live/log-archive/main.tf`](../../live/log-archive/main.tf)):

- **Object Lock in COMPLIANCE mode, 7 years** — enabled at bucket creation (it cannot be
  added later) and shortenable by nobody, including root
- **Versioning enabled**, public access fully blocked, insecure transport denied
- **SSE-KMS with a customer-managed key**, rotated annually — because an archive
  encrypted with a key someone can disable is deletable by another name
- **The key policy separates administration from use**: `security-tooling` can decrypt to
  run Athena queries but holds no `kms:PutKeyPolicy`, `kms:ScheduleKeyDeletion` or
  `kms:DisableKey`. **No principal holds both.** Scheduling the key's deletion is itself
  an alarm.
- **Two clocks that must not disagree** — the lifecycle rule transitions to Glacier at 365
  days (12 months hot and searchable, ISM-1988) and expires at 2555 days = 7 years,
  matching the Object Lock retention exactly (ISM-0859, NAA disposal authority per
  ISM-1989). A lifecycle that expires an object the lock still protects fails quietly.
- **Writers are constrained by the bucket policy** to the trail, Config, VPC flow logs and
  Resolver query logs — each scoped by `aws:SourceOrgID`, and the trail additionally by
  `aws:SourceArn`. A workload administrator can neither write nor erase.
- **No human access.**

**The organisation trail**
([`live/security-tooling/trail.tf`](../../live/security-tooling/trail.tf)) is an
organisation-wide, multi-Region trail with **log file validation enabled** — digest files
prove logs were not altered. It records **three** event categories, not one, because for
this business the threat is not someone changing configuration, it is someone **reading
the data** through a private path with valid credentials:

1. **Management events** — the control plane
2. **Data events** — S3 object-level access, scoped to PROTECTED buckets (estate-wide data
   events on hot buckets is the budget flip; the narrowing is a registered accepted risk)
3. **Network activity events** — VPC endpoint calls, so the private path is recorded
   rather than assumed

The trail ran **alongside** the interim trail for an overlap window and was proven to
cover its scope by comparing delivered events before cutover — a gap between trails is the
one hole that can never be backfilled.

**Detection.** AWS Config records configuration items on a two-speed schedule; GuardDuty,
Security Hub CSPM, Inspector and Macie run estate-wide, delegated once at the organisation
level. Four watchers cover the platform's own integrity. Findings route by severity through
EventBridge to the SOC against a contracted SLA.

**Normalisation and the SOC seam.** Security Lake normalises to OCSF
([`live/log-archive/securitylake.tf`](../../live/log-archive/securitylake.tf)); SQS
connector queues, one per prefix, feed the SOC's Sentinel. Sentinel holds a **copy at
most, never the record** — the evidence plane must outlive the SOC contract.

**Time.** A common time source across the estate (ISM-0988), evidenced at
`irap/phase-04/time-sync-attestation.json`.

**Continuous monitoring.** Drift detection runs on a schedule against every state leaf;
the checks workflow gates every push. Evidence exports land under
`s3://kestrel-log-archive/irap/phase-<n>/`, each filed against the ISM controls it
satisfies — the estate re-runs its own battery rather than assembling a pack at
assessment time.

## 21. Software development

Platform infrastructure code is developed in this repository under the change-management
controls in §19.1. Static analysis (Checkov, plus custom tag and naming policies) and
secret scanning (gitleaks) gate every pull request. The checks workflow holds **no cloud
credentials** by design.

Tenant application development is governed by each workload's own SDLC and SSP.

**AI governance (new in June 2026).** The June 2026 ISM added seven AI controls covering
prevention of classified data exposure to AI systems, human-approval flags and behavioural
baselines. Kestrel uses AI-assisted coding tools against this repository. The controlling
facts are: the repository contains **no classified data and no credentials** — every
identifier is a documented placeholder — and no AI tool holds cloud access or can merge a
change, because every change requires CODEOWNERS approval by a human and passes the same
gates. AI use in workloads processing PROTECTED data is out of scope for this SSP and
requires its own assessment against these controls.

## 22. Database systems

The landing zone operates no databases. Database security for tenant workloads is the
workload owner's responsibility; the platform contributes encryption-at-rest enforcement
through declarative policies, network isolation (§24), and Macie for data classification
([`live/security-tooling/classification.tf`](../../live/security-tooling/classification.tf)).

## 23. Email

The system sends no email to end users. AWS account contact addresses are monitored
distribution lists, set identically on every account by the baseline
([`modules/account-baseline/main.tf`](../../modules/account-baseline/main.tf)):
`aws-billing@`, `aws-operations@` and `aws-security@kestrel.com.au`. The account email
scheme is ADR-0001.

Corporate email security is enterprise IT's responsibility, outside this boundary.

## 24. Networking

**Fabric.** AWS Cloud WAN with a **segment per zone**, chosen over Transit Gateway. IPAM
sits behind every CIDR — the `network-denies` SCP denies a `CreateVpc` where no IPAM pool
was specified at all, which is the actual failure mode: a hand-carved CIDR
([`live/network/`](../../live/network/)).

**Egress.** One logged egress per Region, through an inspection VPC running AWS Network
Firewall ([`modules/inspection-vpc/`](../../modules/inspection-vpc/),
[`modules/firewall-rules/`](../../modules/firewall-rules/)). No workload account has its
own internet gateway — this is denied by SCP, not by convention.

**Segmentation.** Zone segments do not route to each other by default; the Sydney–Melbourne
peering link carries **no default route**, which is what makes the active-active claim
structural rather than aspirational.

**Logging.** VPC flow logs and Route 53 Resolver query logs are written by the VPC module
in **every** account ([`modules/account-baseline/network/`](../../modules/account-baseline/network/)),
delivered by the service directly to the archive scoped by organisation ID — there is no
account-level toggle to turn them off.

## 25. Cryptography

**At rest.** SSE-KMS with customer-managed keys for the evidence plane, rotated annually
on a 365-day rotation period with a 30-day deletion window
([`live/log-archive/main.tf`](../../live/log-archive/main.tf)). The administration/use
split described in §20 is the control that matters: rotation without that split is a
weaker claim than it appears. Evidence:
`irap/phase-04/archive-cmk-policy-and-rotation.json` (ISM-0459).

**In transit.** TLS 1.2 or higher with ASD-approved algorithms throughout, including the
Event Hub hop to the SOC. The archive bucket policy explicitly denies any request where
`aws:SecureTransport` is false. Evidence: `irap/phase-04/tls-posture-scan.json`
(ISM-1139).

**Key custody.** AWS KMS provides FIPS 140-3 validated modules in the Australian Regions.
Root MFA uses YubiKey 5 FIPS hardware (ADR-0002). Terraform state is encrypted in an
in-boundary S3 bucket with native S3 state locking — HCP Terraform was declined because it
has no Australian Region (ADR-0003), and state that leaves the boundary is a sovereignty
break regardless of how it is encrypted.

## 26. Gateways

The inspection VPC and Network Firewall constitute the system's gateway function (§24).
All egress traverses it and is logged; there is no split-tunnel and no per-account
exception. Cross-domain transfer between security domains does not occur — the system
handles a single classification boundary at PROTECTED.

## 27. Data transfers

**Into the system.** Tenant data arrives through workload-specific ingress paths defined
in each workload's SSP.

**Within the system.** Log data flows from every account to the Object-Locked archive as
described in §1.4, service-to-service, never through a human.

**Out of the system.** Two egress paths exist and both are deliberate:

1. **To the SOC's Sentinel** — OCSF-normalised security events through SQS connectors.
   TLS-protected, a copy of the record, never the record itself.
2. **To assessors** — evidence exports under `s3://kestrel-log-archive/irap/phase-<n>/`,
   released deliberately as an assessment pack.

The `resource-perimeter` SCP prevents Kestrel principals from writing to any resource
outside the organisation, and the `org-perimeter` RCP prevents external principals from
reading Kestrel resources even where a resource policy would grant them access. Together
these close the unmanaged-transfer path in both directions.

---

## Appendix A — Known gaps and open findings

Disclosed rather than omitted, per the assessment rules in §"How to read this document".

| Ref | Control | Description | Owner | Status |
|-----|---------|-------------|-------|--------|
| **FIND-019** | ISM-1553 | Application control not enforced on all managed endpoints | platform-team | Open, expiry 2026-12-01 |
| **FIND-012** | ISM-0859 | Melbourne replica lifecycle carried no expiry rule | platform-team | **Fixed** — PR #214; replica-retention test added to the battery |
| — | Transitional OU | ~60 brownfield accounts carry org-root inherited controls only, detective posture pending graduation | platform-team | Known, bounded, graduating individually (§19.4) |
| — | ISM-2104–2107 | Personnel public-disclosure controls (new June 2026) — policy control, no technical enforcement point | CISO | Policy issued; acknowledgement cycle running |
| — | `WorkloadDeploy` | Uses `PowerUserAccess`; scoped per-workload policy required before any agency-facing Prod workload | platform-team | Time-bounded, flip condition stated (§17) |
| — | Data events | CloudTrail S3 data events scoped to PROTECTED-prefixed buckets rather than estate-wide, on cost grounds | platform-team | Registered accepted risk (§20) |

## Appendix B — Evidence index

All evidence resolves under `s3://kestrel-log-archive/irap/phase-<n>/`. The authoritative
control-to-evidence mapping is [`docs/assessment/matrix.yaml`](../assessment/matrix.yaml)
(pinned to ISM release `2026.06`); CI fails any pull request containing an unresolvable
path, an unowned gap, or a control absent from the pinned release.

| ISM control | Claim | Evidence object |
|-------------|-------|-----------------|
| ISM-1988 | Event logs searchable for 12 months | `phase-04/athena-query-battery.json` |
| ISM-0859 | Event logs retained 7 years | `phase-04/log-retention-lifecycle.json` |
| ISM-0988 | Common time source across the estate | `phase-04/time-sync-attestation.json` |
| ISM-1526 | Changes travel a reviewed, gated pipeline | `phase-02/pipeline-end-to-end-run.json` |
| ISM-1175 | Privileged access requested, approved, time-bound, logged | `phase-07/elevation-lifecycle-battery.json` |
| ISM-1507 | Privileged users use separate privileged accounts | `phase-07/standing-privilege-enumeration.json` |
| ISM-0580 | Event logging centralised and protected from modification | `phase-04/object-lock-and-bucket-policy-tests.json` |
| ISM-1906 | Security events analysed in a timely manner | `phase-04/finding-to-acknowledgement-timings.json` |
| ISM-0459 | Archive keys customer-managed and rotated annually | `phase-04/archive-cmk-policy-and-rotation.json` |
| ISM-1139 | Data in transit uses TLS 1.2+ with approved algorithms | `phase-04/tls-posture-scan.json` |
| ISM-1690 | Critical patches within two weeks; 48 hours where exploited | `phase-04/inspector-remediation-windows.json` |
| ISM-1553 | Application control on managed endpoints | **Gap** — FIND-019 |

## Appendix C — Glossary

| Term | Meaning |
|------|---------|
| **ACSC / ASD** | Australian Signals Directorate, publisher of the ISM |
| **Brownfield** | A pre-existing account enrolled into the organisation, not vended by the factory |
| **Evidence plane** | The Object-Locked archive and its query path — the record, owned by Kestrel |
| **IRAP** | Infosec Registered Assessors Program |
| **ISM** | Information Security Manual |
| **JIT** | Just-in-time (privilege elevation) |
| **OCSF** | Open Cybersecurity Schema Framework |
| **Operations plane** | The SOC's Sentinel — holds a copy of security events, never the record |
| **RCP** | Resource Control Policy |
| **SCP** | Service Control Policy |
| **SRA** | AWS Security Reference Architecture |
| **SSP-A** | System Security Plan Annex |
| **Vending** | Creating a new account through the account factory, born governed |
