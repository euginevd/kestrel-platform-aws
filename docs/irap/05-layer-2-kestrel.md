# 05 — Layer 2: The Kestrel landing zone

> **NOT AN IRAP ASSESSMENT.** The author is not an ASD-endorsed IRAP assessor. See
> [README](README.md).

**Layer purpose.** This is the consumer system — the substance of the assessment. Controls
are assessed against ISM June 2026 at PROTECTED, from source configuration and system
documentation.

**Overall layer observation.** The architecture is materially stronger than typical for an
organisation of this size at this classification. Weaknesses concentrate in **claim
precision** — documentation asserting more than the configuration delivers — and in the
brownfield population, rather than in architectural deficiency. Per-control outcomes are
recorded in the [controls matrix](02-cloud-controls-matrix.md).

---

## 1. Guidelines for cyber security documentation

**Assessed outcomes in this area: predominantly Effective.**

The documentation set is complete and internally coherent: SSP, SSP Annex (`matrix.yaml`),
SRMP, CMP and IRP, all version-controlled and changed by reviewed pull request. Two
practices are above the standard usually seen:

- **The Annex is machine-reconciled.** CI fails a pull request containing an unresolvable
  evidence path, an unowned gap, or a control absent from the pinned release. Most control
  matrices decay silently between assessments; this one cannot.
- **The release is pinned** (`ism_release: 2026.06`) with a defined process for moving it.

**Finding — FIND-K01: the SSP claims 27 chapters of coverage but several are
one-paragraph deferrals.** Chapters 8, 9, 10, 12, 15, 16, 22 and 23 largely state
"inherited" or "outside this boundary". That is often *correct* — a landing zone genuinely
has no email system — but the effect is a document that reads as more comprehensive than
its substance. An assessor would ask for each deferral to name the system where the control
*is* assessed. "Corporate email security is enterprise IT's responsibility" identifies an
owner but not an assessed system, which leaves the control unevidenced at the whole-of-
organisation level.

## 2. Guidelines for system monitoring

**Assessed outcomes in this area: predominantly Effective.** The strongest area of the system.

### 2.1 Logging architecture

Assessed against `live/log-archive/main.tf` and `live/security-tooling/trail.tf`:

| Control intent | Implementation | Rating |
|---|---|---|
| Centralised logging (ISM-0580) | Organisation trail, all accounts, both Regions, single sink | Effective |
| Protection from modification | Object Lock COMPLIANCE 7y + versioning + `prevent_destroy` + log file validation | Effective |
| Retention (ISM-0859) | Two aligned clocks: Glacier at 365d, expiry at 2555d, matching the lock | Effective |
| Searchability 12 months (ISM-1988) | Hot in S3 Standard for 365 days, Athena-queryable | Effective |
| Encryption (ISM-0459) | CMK, annual rotation, **admin/use split** | Effective |

**The KMS admin/use split is the strongest single control in the estate.** `security-tooling`
holds `kms:Decrypt`, `kms:DescribeKey` and `kms:GenerateDataKey*` but no `kms:PutKeyPolicy`,
`kms:ScheduleKeyDeletion` or `kms:DisableKey`. The reasoning — *"an archive encrypted with a
key someone can disable is deletable by another name"* — is correct and is the failure mode
most Object Lock implementations miss entirely. Object Lock without key-policy separation is
a much weaker control than it appears, and this system is one of the few that has noticed.

**The three-category trail is correctly reasoned.** Recording Management, Data and
NetworkActivity events because *"the threat is not someone changing configuration, it's
someone reading the data through a private path with valid credentials"* is the right threat
model for a PROTECTED SaaS host, and NetworkActivity events for VPC endpoint calls is a
control few consumers implement.

### 2.2 Detecting absence of signal

**Effective, and notably mature.** The silence alarms use
`treat_missing_data = "breaching"`, correctly recognising that a stopped source produces *no
datapoints* rather than a zero. The trail-delivery alarm uses CloudTrail's own
`S3DeliveryFailures` metric rather than a log query — the reasoning that *"the one alarm
that must never depend on the trail is the trail-failure alarm"* is exactly right.

The decision that these alarms are **Kestrel-only** because *"the provider cannot watch its
own feed go quiet"* is a genuine insight about monitoring outsourcing that most consumers
do not reach.

### 2.3 The data-events scope limitation — **FIND-K02**

CloudTrail data events are scoped to `arn:aws:s3:::kestrel-protected-*`:

```hcl
field_selector {
  field       = "resources.ARN"
  starts_with = ["arn:aws:s3:::kestrel-protected-"]
}
```

The system owner discloses this (SRMP R-09) and rates the residual Medium with
compensating controls: Macie, the tag policy, perimeter SCPs, Config drift.

**The assessment does not accept the compensating-control argument as stated**, for a
specific reason the SRMP does not address: **object-level read visibility has no
substitute**. Macie tells you PROTECTED data exists somewhere unexpected. The tag policy
governs tags, not bucket names. The perimeter SCPs constrain where data may go, not who read
it. None of these answer the forensic question *"which objects did this principal read, and
when?"* — which is the exact question an insider-exfiltration incident turns on, and the
threat the system names as its primary design threat.

There is an internal inconsistency here worth stating plainly: the system identifies
insider data access as **the** primary threat, builds NetworkActivity logging specifically
to catch the private read path, and then scopes object-level read logging by a bucket-naming
convention. IRP §10.6 acknowledges the consequence honestly — *"record the limitation in the
incident report rather than presenting partial coverage as complete"* — which is the right
disclosure, but disclosure is not mitigation.

**Additionally, nothing enforces the naming convention.** No SCP, Config rule or tag policy
was found requiring that buckets holding PROTECTED data carry the `kestrel-protected-`
prefix. The control's coverage depends on a convention that is documented but not enforced,
which makes it a convention rather than a control.

**Recommendation.** Either enforce the prefix (Config rule plus SCP denying `s3:CreateBucket`
without it for PROTECTED-tagged accounts), or scope data events by resource **tag** rather
than name prefix, so classification drives logging rather than a naming habit.

## 3. Guidelines for authentication hardening and access control

**Assessed outcomes in this area: mixed — see the matrix for per-control outcomes.**

### 3.1 Strong elements — Effective

- **No IAM users, no long-lived access keys.** Verified across the configuration; no
  `aws_iam_access_key` or `aws_iam_user` resource appears anywhere
- **Federation with JIT elevation.** Entra PIM, groups arriving by SCIM only while an
  activation is live. `sg-aws-*-jit` groups hold no standing grant
- **Session durations** at 1h privileged / 4h read-only, correctly reasoned as the
  controllable half of the de-elevation overhang
- **`log-archive` receives no assignment block at all** — the account holding every log is
  one nobody can log into. The comment *"that absence is the control, not an oversight"* is
  the correct instinct, and the assessment confirms it holds in configuration
- **Assignments derive from OU membership**, so an account moved between OUs gains and loses
  the right access on the next plan

This is a genuinely strong identity design.

### 3.2 `WorkloadDeploy` uses `PowerUserAccess` — **FIND-K03**

```hcl
WorkloadDeploy = {
  duration = "PT1H"
  managed  = "arn:aws:iam::aws:policy/PowerUserAccess"
}
```

Granted to `sg-aws-workload-engineers` at `Workloads/Non-Prod`.

The system owner discloses this with a stated flip condition: replaced *"the moment an
agency-facing workload lands in Prod"*. The assessment rates it **High** rather than
accepting the deferral, on three grounds:

1. **`PowerUserAccess` is very broad** — effectively everything except IAM and Organizations.
   At PROTECTED it is not a defensible standing grant for a named group, even in Non-Prod.
2. **The flip condition is not enforceable by any mechanism found.** It depends on someone
   remembering, at a moment defined by a business event rather than a technical trigger.
   Nothing in the pipeline, the exception register or the assessment battery detects that
   the condition has been met. The exception register (`exceptions.yaml`) has exactly the
   machinery to carry this — plan-time expiry assertion — and this is not on it.
3. **"Non-Prod has no production data" is a policy statement, not an enforced control.** No
   technical control was found preventing PROTECTED data reaching a Non-Prod account. Macie
   would *detect* it after the fact; nothing prevents it.

**Expected.** Either a scoped policy now, or the deferral registered in `exceptions.yaml`
with owner, expiry and compensating control, so it expires loudly rather than silently.

### 3.3 Break-glass and root custody — **No visibility**

The design ([ADR-0002](../adr/ADR-0002-root-custody.md)) is strong: CyberArk custody, two
YubiKey 5 FIPS keys in two cities both registered at setup, zero access keys, two-person
rule, quarterly witnessed drills, break-glass deliberately outside Entra ID so an IdP outage
cannot lock out the estate that would fix it. The last point is a real insight — many
organisations discover the circular dependency during the incident.

**FIND-K04: the two-person rule is procedural with no technical enforcement.**
AWS root authentication cannot enforce a witness, so the control depends entirely on the
CyberArk checkout log correlating with CloudTrail. That correlation is described in IRP
§10.1 as an incident-response step, but no *automated* reconciliation was found — nothing
periodically compares root CloudTrail events against CyberArk checkouts and alarms on a
mismatch. Detection therefore depends on someone performing the comparison during an
incident, i.e. after the event that matters.

This is also **unassessable from documentation**. Whether ceremonies actually run with a
witness, and whether drills genuinely occur quarterly against a locked scenario, requires
interviews and drill records. Recorded as No visibility on that basis, not on a design
defect.

### 3.4 The `deny-root` SCP is narrower than the SSP implies — **FIND-K05**

`deny-root.json` denies all actions where `aws:PrincipalArn` matches `arn:aws:iam::*:root`.
This is correct and standard. But note it applies at the **organisation root**, and SCPs
**do not apply to the management account**. The SSP describes `deny-root` as covering "newly
invited accounts before the sweep runs", which is accurate — but a reader could infer root
is denied estate-wide. Management-account root is governed by ADR-0002's procedural controls
only, which the SSP does state elsewhere.

Low severity — the control is right and the SSP is not wrong. The two statements simply sit
far apart in the document and invite a reader to over-conclude.

## 4. Guidelines for network hardening

**Assessed outcomes in this area: predominantly Effective.**

- **Cloud WAN, segment per zone**, no default route on the Sydney–Melbourne peering link.
  The observation that *"a Melbourne that reaches the internet through Sydney is a pilot
  light with better marketing"* is the correct structural test for an active-active claim
- **No workload account has its own egress** — denied by SCP in both IPv4 and IPv6, not by
  convention. IPv6 is included, which is frequently missed
- **IPAM-only VPC creation**, with a `Null` condition catching the real failure mode
  (`CreateVpc` with no pool specified at all — a hand-carved CIDR)
- **Flow logs and Resolver query logs** written by the service in every account, scoped by
  org ID, with no account-level toggle
- **Default VPCs deleted in both Regions** at account birth

### 4.1 Egress allow-list breadth — **FIND-K06**

```hcl
allowed_domains = [
  ".kestrel.com.au",
  ".amazonaws.com",
  ".github.com",
]
```

`.amazonaws.com` is an extremely broad allowance. It covers **every AWS service endpoint in
every account in the world**, including S3 buckets belonging to anyone. For a system whose
primary named threat is insider data exfiltration, a domain allow-list permitting egress to
arbitrary third-party S3 buckets is a material gap in the egress control.

The `resource-perimeter` SCP is the compensating control and is genuinely effective against
*authenticated* writes to external resources using Kestrel principals. It does not constrain
an unauthenticated HTTPS PUT to an attacker-controlled bucket that permits anonymous writes,
nor exfiltration over an AWS-endpoint-shaped channel from a compromised workload instance.

`.github.com` is similarly broad — it permits egress to any GitHub repository, including
attacker-controlled ones. For a platform that deliberately vendors all modules and pulls no
third-party code at apply time, that breadth is not obviously required at runtime.

**Recommendation.** Narrow to specific service endpoints; prefer VPC endpoints with endpoint
policies over domain allow-listing for AWS services, since endpoint policies can enforce
`aws:PrincipalOrgID` and `aws:ResourceOrgID` in a way that TLS SNI filtering cannot.

## 5. Guidelines for system management

**Assessed outcomes in this area: mixed — see the matrix for per-control outcomes.**

### 5.1 Change management — Effective

Reviewed pull request, CODEOWNERS on protected `main`, no-credential checks stage, split
plan/apply OIDC roles, per-leaf state, modules pinned by git tag, lockfile verified with
`-lockfile=readonly`. The reasoning that the checks stage holds no credentials *"so there is
nothing here worth stealing"* is correct supply-chain thinking.

**Assumed enabled per A2** — all workflows are `*.yml.disabled` in the repository. Recorded
as OBS-03; if not enabled, every control in this subsection is **Ineffective**.

### 5.2 Brownfield accounts — **FIND-K07**

~60 accounts sit in `Transitional`, carrying only the org-root inherited set. Per
`attachments.tf`: *"Transitional deliberately carries NOTHING beyond the org-root inherited
set"*.

This means the ~60 accounts — the numerical majority of the estate — **do not carry
`network-denies`**. They may have their own internet gateways, public IP addresses, and
hand-carved CIDRs outside IPAM. They are seen (trail, Config, GuardDuty, Security Hub) but
not constrained.

The system owner discloses this honestly (SRMP R-05, High residual, expiry 2027-06-30) and
the assessment credits both the disclosure and the refusal to rate it optimistically. The
finding is raised at High regardless, because:

1. **At PROTECTED, the scope question is unanswered.** Nothing in the pack establishes
   whether any Transitional account currently holds PROTECTED data. If any does, it holds it
   under materially weaker controls than the SSP describes for the estate. This is the single
   most important unanswered question in the assessment.
2. **No graduation rate or schedule exists.** The expiry is 2027-06-30 — roughly 11 months
   for ~60 accounts — with no per-account plan, no monthly target, and no evidence of
   progress to date. An expiry without a rate is a date, not a plan.
3. **The register tracks the population, not the risk within it.** No triage was found
   ranking Transitional accounts by data sensitivity, internet exposure or privilege.

**Expected.** A classification triage of all ~60 accounts, an explicit statement of whether
any holds PROTECTED data, and a graduation schedule with monthly targets. If any holds
PROTECTED data, that account is either graduated immediately or the data is moved.

### 5.3 Config recorder — Effective, with an observation

The two-speed recording design is well-reasoned: continuous for identity, network, KMS, S3
and CloudTrail types where *"a change between snapshots is the change that matters"*, daily
for high-churn types. The warning that `include_global_resource_types` set in both Regions
double-bills IAM records — *"a cost bug that looks exactly like working coverage"* — shows
operational maturity.

**OBS-02.** `continuous_types` omits `AWS::EC2::Instance` and `AWS::RDS::DBInstance`. Both
are high-churn, so daily is defensible on cost. But for an insider-threat model, a
short-lived instance created and destroyed between daily snapshots would leave no Config
record. CloudTrail captures the API calls, so this is not a coverage hole — it is a
reconstruction-effort observation, not a finding.

## 6. Guidelines for cryptography

**Assessed outcomes in this area: predominantly Effective.**

CMKs with annual rotation and 30-day deletion windows; the admin/use split; TLS 1.2+ with
`aws:SecureTransport` denial on the archive bucket; FIPS 140-3 modules via KMS; YubiKey 5
FIPS for root; state in-boundary.

**FIND-K08: the replica key policy lacks the admin/use split.** `replica_key` in
`replica.tf` contains only an `AccountAdministration` statement, where the primary
`logs_key` carries the explicit `SecurityToolingUseOnly` split and a documented rationale
that *"nobody holds both"*.

The replica is functionally read-only for durability, so the practical exposure is limited —
but the asymmetry is exactly the class of defect FIND-012 already caught once on this same
pair of buckets, where the replica's lifecycle diverged from the primary's. The lesson from
FIND-012 — *"the two-clocks-must-not-disagree care applies to every copy, not just the
original"* — generalises to key policy and has not been applied there.

## 7. Guidelines for data transfers and content filtering

**Assessed outcomes in this area: mixed — see the matrix for per-control outcomes.**

The perimeter model is well-constructed in three directions. `org-perimeter` (RCP) correctly
handles the confused-deputy case with `aws:SourceOrgID` and `aws:PrincipalIsAWSService`.
`resource-perimeter` (SCP) denies writes to resources outside the org.

### 7.1 Perimeter service coverage — **FIND-K09**

Both perimeter policies enumerate the same service list:

```json
"Action": ["s3:*", "kms:*", "sqs:*", "secretsmanager:*"]
```

(`org-perimeter` adds `sts:AssumeRole`.)

Services **not** covered, each a viable data-egress path:

| Service | Egress path |
|---|---|
| `ssm:*` | Parameter Store — cross-account parameter sharing |
| `ecr:*` | Container images can carry data layers |
| `logs:*` | CloudWatch Logs cross-account destinations and subscription filters |
| `events:*` | EventBridge cross-account bus targets |
| `sns:*` | Cross-account topic subscriptions — notably absent while `sqs` is present |
| `dynamodb:*`, `rds:*` | Cross-account snapshot sharing |
| `lambda:*` | Cross-account function invocation |

`sns` being absent while `sqs` is present looks like an oversight rather than a decision —
the two are near-equivalent as cross-account messaging paths, and no rationale for the
distinction appears anywhere in the pack.

**The absence of `logs:*` is the most significant.** A CloudWatch Logs subscription filter
to a cross-account Kinesis destination is a well-known, high-bandwidth, low-visibility
exfiltration channel, and it is not covered.

**Expected.** Either extend the service list to cover the data-bearing services above, or
document why each omission is acceptable. The data perimeter is described in the SSP as
"closed in three directions"; on the evidence it is closed for four services.

### 7.2 Security Lake subscriber scope — **OBS-04**

The SOC subscriber is granted exactly one source:

```hcl
source {
  aws_log_source_resource {
    source_name    = "CLOUD_TRAIL_MGMT"
    source_version = "2.0"
  }
}
```

Least privilege, correctly applied — and revocation at contract end is deleting one
resource, which is good design.

But the SSP and IRP describe the SOC as providing 24×7 monitoring and first-line triage
across the estate. A SOC receiving **only CloudTrail management events** cannot see VPC flow
logs, Route 53 queries, WAF events or Security Hub findings — several of which the IRP's own
playbooks assume the SOC is watching. Either the subscriber scope is narrower than the
operating model requires, or the SOC's role is narrower than the documents describe. Both
are defensible; the mismatch is not.

## 8. Guidelines for cyber security incidents

**Assessed outcomes: Effective for examinable design; No visibility for operation.**

The routing design is strong: page / queue / dashboard specified deliberately rather than
left to provider defaults, with root use and evidence tampering paging at any severity
because *"what makes them urgent is what they are, not how they were scored"*. The tamper
rule correctly includes the KMS events (`ScheduleKeyDeletion`, `DisableKey`,
`DisableKeyRotation`, `PutKeyPolicy`) as the path around Object Lock.

Operational effectiveness — whether pages are answered, whether the 5-minute target is met,
whether drills occur — cannot be assessed without interviews and records. **No visibility.**

**FIND-K10: the SNS page topic has a single delivery path and no escalation.**
`aws_sns_topic.page` is the target for every paging rule, including the tamper and silence
alarms. No subscription resources, no escalation policy, and no dead-letter handling for the
topic itself were found in the configuration.

The failure mode matters given this system's own reasoning: the alarms exist because
*"everything downstream keeps reporting healthy while the record quietly stops existing"*.
The same logic applies one level up — if SNS delivery fails, or the on-call subscription is
stale, every one of these carefully-designed alarms fires into nothing, silently. The system
watches its log sources for silence but does not watch its own alerting path for silence.

## 9. Essential Eight posture

| Mitigation | Assessment |
|---|---|
| Application control | **Not implemented** — FIND-019, expiry 2026-12-01 (system owner's register) |
| Patch applications | Inspector + stated windows — Effective by design; workload-owner executed |
| Configure Office macro settings | Not applicable to the platform; corporate IT |
| User application hardening | Corporate IT — outside boundary |
| Restrict administrative privileges | **Effective** — JIT, no standing privilege, no IAM users |
| Patch operating systems | Inspector + golden AMIs; workload-owner executed |
| Multi-factor authentication | **Effective** — Entra ID, phishing-resistant for privileged |
| Regular backups | Object-Locked archive + cross-Region replica; **workload data backup not addressed** |

**FIND-K11: workload data backup is not addressed anywhere in the pack.** The archive
covers *logs*. ADR-0005 covers *continuity of service*. Neither addresses backup and
restoration of tenant data, and no document assigns that responsibility. It is probably the
workload owner's, but the SSP's responsibility table does not say so, which leaves a gap in
the shared-responsibility model rather than in the platform.

## 10. Layer 2 findings summary

| Ref | Finding | Potential impact area |
|-----|---------|----------------------|
| **FIND-K03** | High | `WorkloadDeploy` uses `PowerUserAccess` with an unenforceable flip condition |
| **FIND-K07** | High | ~60 brownfield accounts uncontrolled by the zone layer; PROTECTED data holding unknown |
| **FIND-K02** | Moderate | CloudTrail data events scoped by an unenforced naming convention |
| **FIND-K04** | Moderate | Root two-person rule has no automated CloudTrail/CyberArk reconciliation |
| **FIND-K06** | Moderate | Egress allow-list permits `.amazonaws.com` and `.github.com` broadly |
| **FIND-K09** | Moderate | Perimeter policies cover four services; `logs`, `sns`, `ssm`, `ecr` and others omitted |
| **FIND-K10** | Moderate | SNS paging path has no escalation, no subscription redundancy, no self-monitoring |
| **FIND-K01** | Low | SSP chapter deferrals do not name the system where the control is assessed |
| **FIND-K05** | Low | `deny-root` scope could be misread as estate-wide |
| **FIND-K08** | Low | Replica KMS key policy lacks the admin/use split applied to the primary |
| **FIND-K11** | Low | Workload data backup responsibility unassigned |
| **OBS-02** | Observation | Config continuous types omit EC2/RDS instances |
| **OBS-04** | Observation | SOC subscriber scope narrower than the documented SOC role |

## 11. Layer 2 rating

**Observation.** The architecture is well above the standard typical for a scale-up at PROTECTED. Several
controls — the KMS admin/use split, silence-as-a-signal alarming, `log-archive` with no
human access path, IPv6-inclusive egress denial, the exception register with plan-time
expiry assertions — are genuinely sophisticated and would be credited by any assessor.

The rating is held below Effective by two High findings. FIND-K07 (brownfield) is the more
serious: on the system's own account, the numerical majority of the estate does not carry
the controls the SSP describes, and whether any of those accounts holds PROTECTED data is
not answered anywhere in the pack. That question must be answered before authorisation, and
its answer could move this rating in either direction.
