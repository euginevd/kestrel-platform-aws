# 03 — Findings register

> **NOT AN IRAP ASSESSMENT.** The author is not an ASD-endorsed IRAP assessor. See
> [README](README.md).

## How to read this register (IRAP-AR-0034)

**This register does not rate risk.** Per IRAP-AR-0034, an IRAP assessor articulates
potential impact but does not rate risks on behalf of the assessed entity. Each finding
therefore states **what was observed**, **what was expected**, and **the potential impact**.
Assigning likelihood, consequence and a risk rating is the assessed entity's responsibility
and belongs in Kestrel's [SRMP](../security/security-risk-management-plan.md).

**Findings are ordered by the assessor's view of the urgency with which the entity should
consider them** — not by a risk score.

**Recommendations describe intent, not design** (IRAP-AR-0033). Where a remediation approach
is mentioned it is offered as an option to consider, not a prescription.

All weaknesses are articulated as early as possible in the pack (IRAP-AR-0032); the two
findings the assessor considers most consequential are stated in the
[Security Assessment Report](01-security-assessment-report.md) executive summary.

---

## Index

| Ref | Control | Finding | Layer |
|-----|---------|---------|-------|
| [FIND-K07](#find-k07) | ISM-1493, ISM-0140 | ~60 brownfield accounts outside the zone control layer; data holding unestablished | 2 |
| [FIND-K03](#find-k03) | ISM-1380 | `WorkloadDeploy` grants `PowerUserAccess` with an unenforceable flip condition | 2 |
| [FIND-T03](#find-t03) | ISM-0873, ISM-1546 | Standing GitHub credential contradicts the SSP's "no long-lived credentials" claim | 3 |
| [FIND-K02](#find-k02) | ISM-0109 | Data-event logging scoped by an unenforced naming convention | 2 |
| [FIND-K09](#find-k09) | ISM-1428 | Data perimeter covers four services; data-bearing services omitted | 2 |
| [FIND-K06](#find-k06) | ISM-1182 | Egress allow-list permits `.amazonaws.com` and `.github.com` | 2 |
| [FIND-T01](#find-t01) | ISM-1175 | Privileged elevation approval workflow not evidenced | 3 |
| [FIND-T06](#find-t06) | ISM-0873, GOV-11 | CyberArk holds the root credential with no assurance position | 3 |
| [FIND-K10](#find-k10) | ISM-1906 | Alerting path has no redundancy, escalation or self-monitoring | 2 |
| [FIND-K04](#find-k04) | ISM-1685 | Root two-person rule has no automated reconciliation | 2 |
| [FIND-T05](#find-t05) | ISM-1906 | SOC subscriber scope inconsistent with documented SOC role | 3 |
| [FIND-T07](#find-t07) | ISM-1569 | No mechanism verifies tenant SSPs exist before vending | 3 |
| [FIND-T04](#find-t04) | GOV-11 | GitHub carries no supplier assurance despite control-plane criticality | 3 |
| [FIND-T02](#find-t02) | ISM-1163 | IdP compromise not modelled as a discrete risk; no IRP playbook | 3 |
| [FIND-A01](#find-a01) | ISM-1569 | AWS inheritance reference unversioned and undated | 1 |
| [FIND-A02](#find-a02) | ISM-1395, ISM-1569 | Service-by-Region assessed scope not confirmed | 1 |
| [FIND-K11](#find-k11) | ISM-1808 | Tenant data backup responsibility unassigned | 2 |
| [FIND-K01](#find-k01) | ISM-0027 | SSP deferrals do not name the system where the control is assessed | 2 |
| [FIND-K08](#find-k08) | ISM-1162 | Replica key policy lacks the primary's administration/use split | 2 |
| [FIND-K05](#find-k05) | ISM-1685 | `deny-root` scope may be misread as estate-wide | 2 |
| [OBS-01](#observations) – [OBS-05](#observations) | — | Observations | various |

---

## FIND-K07

**Brownfield accounts sit outside the zone control layer, and their data holding is not
established**

| | |
|---|---|
| **Control** | ISM-1493, ISM-0140, ISM-1181 |
| **Layer** | 2 — Kestrel |
| **Outcome affected** | ISM-1493 Effective for vended accounts only |
| **Objects examined** | `live/management/organisation/transitional.tf`, `attachments.tf`, SRMP R-05 |
| **Method** | Examine |

**Observed.** Approximately 60 accounts sit in the `Transitional` OU. Per `attachments.tf`:
*"Transitional deliberately carries NOTHING beyond the org-root inherited set."* These
accounts inherit `deny-root`, `region-deny`, `org-perimeter`, `resource-perimeter` and
`protect-platform`, but **not** `network-denies`. They may therefore hold their own internet
gateways, public IP addresses and VPCs created outside IPAM.

No examined object establishes whether any Transitional account currently stores, processes
or communicates PROTECTED data. No graduation schedule, monthly target or progress record
was found. No triage ranking these accounts by data sensitivity, internet exposure or
privilege was found.

**Expected.** For a system seeking authorisation at PROTECTED, the controls described in the
SSP apply to all accounts holding PROTECTED data, or the accounts that do not carry those
controls are demonstrably established as not holding such data.

**Potential impact.** The numerical majority of the estate operates without the network
containment the SSP describes. If any Transitional account holds PROTECTED data, that data
is subject to materially weaker controls than the system's documentation represents —
including the possibility of unfiltered, uninspected egress. The absence of a data-holding
determination means neither the entity nor an authorising officer can currently size this
exposure.

**Assessor note.** The entity discloses this openly (SRMP R-05, expiry 2027-06-30) and
declines to rate its own residual optimistically. That transparency is credited. The finding
is raised because **disclosure of a gap is not closure of it**, and because the unanswered
data-holding question is the single most consequential unknown in the assessment.

**Recommendation.** Consider establishing, as a priority, whether any Transitional account
holds PROTECTED data, and recording that determination. Consider a graduation sequence
prioritised by exposure rather than by convenience, with a rate that visibly retires the
population before the accepted expiry.

---

## FIND-K03

**`WorkloadDeploy` grants `PowerUserAccess` with an unenforceable flip condition**

| | |
|---|---|
| **Control** | ISM-1380 |
| **Layer** | 2 — Kestrel |
| **Outcome** | **Ineffective** |
| **Objects examined** | `live/identity/permission-sets.tf`, `assignments.tf`, SSP §17 |
| **Method** | Examine |

**Observed.** The `WorkloadDeploy` permission set attaches the AWS managed policy
`PowerUserAccess` and is granted to `sg-aws-workload-engineers` across `Workloads/Non-Prod`.
`PowerUserAccess` permits effectively all service actions except IAM and Organizations
management.

The entity states this will be *"replaced with a per-workload scoped policy the moment an
agency-facing workload lands in Prod."* No examined object implements, detects or enforces
that condition. It is not present in the exception register (`exceptions.yaml`), which does
carry plan-time expiry assertions for other deferrals.

The stated compensating property — that Non-Prod contains no production data — appears as a
policy statement. No examined object technically prevents PROTECTED data reaching a Non-Prod
account.

**Expected.** Privileged access limited to what is required for the role. Where a broad
grant is accepted temporarily, the deferral is registered with an owner, an expiry and a
detectable trigger.

**Potential impact.** A standing broad grant held by a named group increases the
consequence of any compromise of a member's identity. Because the flip condition depends on
human recall at a business milestone rather than a technical trigger, the grant may persist
beyond the point the entity itself considers acceptable, without anyone becoming aware.

**Recommendation.** Consider whether the intent of ISM-1380 can be met now with a scoped
policy. If the deferral is retained, consider placing it on the same exception register that
already enforces expiry at plan time, so it fails loudly rather than silently.

---

## FIND-T03

**A standing GitHub credential contradicts the SSP's "no long-lived credentials" claim**

| | |
|---|---|
| **Control** | ISM-0873, ISM-1546, ISM-0027 |
| **Layer** | 3 — GitHub |
| **Objects examined** | `live/management/policies/exceptions.yaml` (EXC-002), SSP §17, §1.4, §4 |
| **Method** | Examine |

**Observed.** EXC-002 registers a long-lived GitHub Personal Access Token scoped to
`admin:org`, held by provisioning automation, with expiry 2027-07-01.

SSP §17 states: *"**No IAM users exist.** There are no long-lived access keys anywhere in the
estate."* SSP §4 justifies GitHub's absence from the supplier assurance regime partly on the
basis that it *"holds no production credentials — OIDC only, no long-lived keys."*

**Expected.** Where a system's documentation makes an absolute claim about credential
hygiene, either the claim holds without exception, or the exception is disclosed at the
point the claim is made.

**Potential impact.** Two distinct impacts:

1. **Technical.** `admin:org` on a GitHub Enterprise organisation permits management of
   organisation membership, teams and repository access. Since deployment authority is
   gated by CODEOWNERS review, compromise of this token represents a credible path toward
   influencing what merges and therefore what applies to the estate.
2. **Assurance.** The SSP's statement is literally accurate — this is a GitHub credential,
   not an AWS IAM key — but reads as broader than it is. An assessor encountering the
   exception after reading the claim would reasonably re-examine every other absolute
   statement in the document. The effect on the documentation's credibility exceeds the
   effect of the credential itself.

**Assessor note.** The exception register functioned exactly as designed: the credential is
registered with owner, reason, compensating control and expiry, reconciled at plan time, and
cannot exist off-register. **This finding was only possible because the register works.**
The finding is against the SSP's precision, not the register.

**Recommendation.** Consider disclosing the exception where the claim is made in SSP §17,
and reflecting it in the SRMP. Consider whether a credential class that requires no
long-lived secret would meet the same provisioning need.

---

## FIND-K02

**Data-event logging is scoped by a naming convention that nothing enforces**

| | |
|---|---|
| **Control** | ISM-0109 |
| **Layer** | 2 — Kestrel |
| **Outcome** | **Ineffective** |
| **Objects examined** | `live/security-tooling/trail.tf`, SRMP R-09, IRP §10.6 |
| **Method** | Examine |

**Observed.** CloudTrail data events are scoped by ARN prefix to
`arn:aws:s3:::kestrel-protected-*`. No examined object — SCP, Config rule, tag policy or
Checkov check — requires that buckets holding PROTECTED data carry that prefix.

**Expected.** Where object-level access logging is scoped, the scoping mechanism is enforced
rather than conventional, so coverage is determinable.

**Potential impact.** PROTECTED data in a bucket not matching the prefix generates no
object-level access record. The forensic question *"which objects did this principal read,
and when?"* would be unanswerable for that data. This bears directly on the threat the
entity itself names as primary: an insider reading data through a private path with valid
credentials.

**On the entity's compensating controls.** The SRMP cites Macie, the tag policy, perimeter
SCPs and Config drift. The assessor's position is that none substitutes for object-level
read visibility: Macie establishes that data exists somewhere unexpected, the tag policy
governs tags rather than bucket names, and the perimeter policies constrain destination
rather than recording access. The entity's IRP §10.6 acknowledges the limitation honestly,
which is appropriate disclosure — but disclosure does not restore the missing record.

**Recommendation.** Consider whether classification, rather than a naming habit, should
drive logging scope — for example by selecting data events on a resource attribute that is
itself enforced. Alternatively, consider enforcing the naming convention so that the
existing scope becomes determinable.

---

## FIND-K09

**The data perimeter covers four services; several data-bearing services are omitted**

| | |
|---|---|
| **Control** | ISM-1428 |
| **Layer** | 2 — Kestrel |
| **Outcome** | Alternate control, with coverage gaps |
| **Objects examined** | `org-perimeter.json`, `resource-perimeter.json`, SSP §19.3 |
| **Method** | Examine |

**Observed.** Both perimeter policies enumerate `s3`, `kms`, `sqs` and `secretsmanager`
(`org-perimeter` additionally covers `sts:AssumeRole`). Services not covered include
`logs`, `sns`, `ssm`, `ecr`, `events`, `lambda`, `dynamodb` and `rds`.

The SSP describes the data perimeter as *"closed in three directions."*

**Expected.** A perimeter intended to prevent unauthorised data movement covers the services
through which data can move, or documents why each omission is acceptable.

**Potential impact.** Each omitted service represents a cross-account data path the
perimeter does not constrain. The absence of `logs` is the most significant: a CloudWatch
Logs subscription filter to a cross-account destination is a high-bandwidth, low-visibility
egress channel. The absence of `sns` alongside the presence of `sqs` appears inconsistent,
as the two are near-equivalent cross-account messaging paths, and no examined object
explains the distinction.

**Recommendation.** Consider extending coverage to the data-bearing services, or recording
the rationale for each omission so the perimeter's actual extent is documented and can be
reasoned about.

---

## FIND-K06

**The egress allow-list permits broad third-party destinations**

| | |
|---|---|
| **Control** | ISM-1182 |
| **Layer** | 2 — Kestrel |
| **Outcome** | **Ineffective** |
| **Objects examined** | `live/network/firewall.tf`, `modules/firewall-rules/` |
| **Method** | Examine |

**Observed.** The Network Firewall domain allow-list is `.kestrel.com.au`,
`.amazonaws.com`, `.github.com`.

**Expected.** Egress filtering that constrains destinations to those required, for a system
whose stated primary threat is data exfiltration by an authorised insider.

**Potential impact.** `.amazonaws.com` permits egress to every AWS service endpoint in every
AWS account globally, including S3 buckets controlled by third parties. `.github.com`
similarly permits egress to arbitrary repositories. The `resource-perimeter` SCP constrains
*authenticated* actions by Kestrel principals but does not constrain an unauthenticated
request to an external endpoint that accepts anonymous writes. The egress control therefore
provides less containment than its presence suggests.

**Recommendation.** Consider whether AWS-service egress can be met through VPC endpoints
with endpoint policies, which can enforce organisation-scoped conditions that TLS SNI
filtering cannot. Consider narrowing `.github.com` to the specific endpoints the delivery
model requires, noting the estate already vendors modules rather than fetching at apply
time.

---

## FIND-T01

**The privileged elevation approval workflow is asserted but not evidenced**

| | |
|---|---|
| **Control** | ISM-1175 |
| **Layer** | 3 — Entra ID |
| **Outcome** | **No visibility** |
| **Objects examined** | `live/identity/assignments.tf`, SSP §17, `matrix.yaml` |
| **Method** | Examine |

**Observed.** The AWS-side configuration confirms that elevation groups (`sg-aws-*-jit`)
hold no standing grant and are populated only during an activation. The approval workflow
itself — who approves, whether self-approval is possible, maximum activation duration,
whether approval is required or only justification — resides in Entra PIM. No PIM
configuration export, attestation or equivalent object was available.

The entity claims ISM-1175 as met in `matrix.yaml`.

**Expected.** Where a control's substance is implemented in a system outside the assessed
estate, an artefact evidencing that configuration is available for examination.

**Potential impact.** The control that governs how privilege is obtained across the entire
estate cannot be assured. If PIM permitted self-approval, or unbounded activation duration,
the AWS-side evidence would look identical to the assessor while the control's intent went
unmet.

**Recommendation.** Consider producing a PIM configuration export as a periodic evidence
object, and bringing PIM configuration change control under a review discipline comparable
to that applied to the Terraform.

---

## FIND-T06

**CyberArk holds the root credential with no assurance position**

| | |
|---|---|
| **Control** | ISM-0873, GOV-11, ISM-1685 |
| **Layer** | 3 — CyberArk |
| **Outcome** | **No visibility** |
| **Objects examined** | ADR-0002, SSP §4, SRMP register |
| **Method** | Examine |

**Observed.** CyberArk holds the management account root credential. No examined object
addresses CyberArk's own configuration, its administrator access model, whether an
administrator can extract a credential without generating a checkout record, or whether its
audit log is tamper-evident. CyberArk does not appear in the SSP §4 supplier table and no
SRMP risk addresses it.

**Expected.** A component holding the credential that can override every other control in
the system carries an assurance position commensurate with that role.

**Potential impact.** The estate's controls ultimately rest on the integrity of this vault.
Its administrators are outside the reach of every control implemented inside AWS. An
unassessed dependency in this position means the effectiveness of root custody — and
therefore ADR-0002's entire control narrative — cannot be assured.

**Recommendation.** Consider bringing CyberArk within the supplier assurance regime applied
to AWS and Microsoft, and documenting whether the two-person rule is enforceable within the
vault itself or relies solely on procedure.

---

## FIND-K10

**The alerting path has no redundancy, escalation or self-monitoring**

| | |
|---|---|
| **Control** | ISM-1906 |
| **Layer** | 2 — Kestrel |
| **Objects examined** | `live/security-tooling/findings.tf`, `alarms.tf` |
| **Method** | Examine |

**Observed.** `aws_sns_topic.page` is the destination for every paging rule, including
evidence-tamper and source-silence alarms. No subscription resources, escalation path,
delivery-failure alarm or dead-letter configuration for the topic itself appears in any
examined object.

**Expected.** An alerting path whose failure is itself detected, for a system that
deliberately alarms on the silence of its other components.

**Potential impact.** If SNS delivery fails or the on-call subscription becomes stale, every
alarm in the design fires into nothing, silently. The system's own design rationale applies
directly: it monitors log sources for silence precisely because *"everything downstream keeps
reporting healthy while the record quietly stops existing."* The same failure mode exists
one level up and is not covered.

**Recommendation.** Consider applying the entity's own silence-detection reasoning to the
notification path itself.

---

## FIND-K04

**The root two-person rule has no automated reconciliation**

| | |
|---|---|
| **Control** | ISM-1685 |
| **Layer** | 2 — Kestrel |
| **Outcome** | **No visibility** |
| **Objects examined** | ADR-0002, IRP §10.1, `live/security-tooling/findings.tf` |
| **Method** | Examine |

**Observed.** Root use pages at any severity — confirmed in the EventBridge rule. The
two-person rule depends on correlating the CyberArk checkout log with CloudTrail. IRP §10.1
describes this correlation as a step performed during incident response. No examined object
performs it periodically or alarms on a mismatch.

**Expected.** Where a control cannot be technically enforced, its verification is automated
so that a violation is detected proximate to the event.

**Potential impact.** An unwitnessed root ceremony, or root use with no corresponding
checkout, would be detected only when someone performed the comparison — that is, during an
incident, after the event that mattered. Whether ceremonies actually occur with a witness
cannot be assured without interview and records.

**Recommendation.** Consider automating the reconciliation between vault checkout records
and root CloudTrail events, so a mismatch raises the same page a tamper attempt does.

---

## FIND-T05

**SOC subscriber scope is inconsistent with the documented SOC role**

| | |
|---|---|
| **Control** | ISM-1906, ISM-1569 |
| **Layer** | 3 — Managed SOC |
| **Objects examined** | `live/log-archive/securitylake.tf`, `main.tf` notifications, SSP §3, IRP §4 |
| **Method** | Examine |

**Observed.** The Security Lake subscriber grants the SOC a single source:
`CLOUD_TRAIL_MGMT`. Separately, S3 bucket notifications deliver per-prefix events to
connector queues. The SSP and IRP describe the SOC as performing 24×7 monitoring and
first-line triage, and IRP playbooks assume SOC visibility of network and data-access
activity. No examined object states which sources the SOC actually monitors, and the two
delivery mechanisms are not reconciled anywhere.

**Expected.** The shared responsibility model states what the provider receives, monitors
and is accountable for detecting (ISM-1569).

**Potential impact.** If the subscriber grant reflects the operating reality, the SOC cannot
triage network-based intrusion or data-access anomalies, and IRP playbooks that assume
otherwise would fail during an incident. If the documents reflect reality, the grant is
narrower than the service requires. Either way, a detection responsibility may be believed
covered by each party and covered by neither.

**Recommendation.** Consider documenting an agreed source list, reconciled against both the
subscriber and connector configurations.

---

## FIND-T07

**No mechanism verifies that tenant SSPs exist before vending**

| | |
|---|---|
| **Control** | ISM-1569, ISM-0027 |
| **Layer** | 3 — Tenant workload owners |
| **Objects examined** | `modules/account-factory/`, `live/management/accounts/`, SSP §1.5 |
| **Method** | Examine |

**Observed.** The SSP defers numerous controls — guest OS hardening, application control,
patching, application security, database security — to "the workload's own SSP." No examined
object requires a tenant SSP to exist before an account is vended, verifies its coverage, or
detects a workload operating without one.

**Expected.** Where controls are deferred to another party, the existence of that party's
security documentation is verifiable.

**Potential impact.** The deferral chain may terminate nowhere: the platform documents that
the workload covers a control, the workload has no SSP, and the control is addressed by
neither. At PROTECTED this produces unowned controls that neither party's documentation
would reveal.

**Recommendation.** Consider making tenant SSP existence a vending precondition, with the
reference recorded in the factory map entry so the deferral chain is traceable.

---

## FIND-T04

**GitHub carries no supplier assurance despite control-plane criticality**

| | |
|---|---|
| **Control** | GOV-11, ISM-0873 |
| **Layer** | 3 — GitHub |
| **Outcome** | Contributes to **Ineffective** for GOV-11 |
| **Objects examined** | SSP §4 |
| **Method** | Examine |

**Observed.** GitHub is excluded from the supplier assurance regime on the stated basis that
it *"holds no production credentials — OIDC only, no long-lived keys; source is not
classified above OFFICIAL."* The first clause is contradicted by EXC-002 (FIND-T03). No
assurance artefact — SOC 2, ISO 27001 or equivalent — is referenced.

GOV-11, elevated in the June 2026 ISM, requires suppliers be *regularly independently
verified*.

**Expected.** Suppliers whose compromise would materially affect the system carry an
assurance position proportionate to that role.

**Potential impact.** GitHub is the control plane for a PROTECTED system: what merges there
determines what applies to the estate. The stated justification addresses confidentiality of
source but not integrity of the deployment path, which is the more consequential exposure.

**Recommendation.** Consider assessing GitHub against the same supplier assurance
expectations applied to AWS and Microsoft, reasoning from its role rather than from the
classification of the data it stores.

---

## FIND-T02

**IdP compromise is not modelled as a discrete risk and has no response playbook**

| | |
|---|---|
| **Control** | ISM-1163, ISM-0576 |
| **Layer** | 3 — Entra ID |
| **Objects examined** | SRMP R-08, IRP §10 |
| **Method** | Examine |

**Observed.** Entra ID compromise is addressed within a general supplier risk (R-08)
covering AWS, Microsoft, the SOC and GitHub collectively. The IRP contains playbooks for
root compromise, pipeline compromise and workload compromise, but none for compromise of the
identity provider.

**Expected.** Scenarios whose consequence differs materially from their peer group are
modelled discretely, with response guidance proportionate to consequence.

**Potential impact.** With no IAM users and no long-lived keys, Entra ID is the sole
authentication path to the estate. Its compromise is estate-wide compromise. Token forgery
or malicious federated credential scenarios have detection and response characteristics
quite unlike those of a generic supplier incident, and responders would have no prepared
guidance.

**Recommendation.** Consider modelling IdP compromise discretely, and developing response
guidance for the case where the identity provider itself is the suspect system — noting the
break-glass path (ADR-0002) is already correctly designed for exactly this contingency.

---

## FIND-A01

**The AWS inheritance reference is unversioned and undated**

| | |
|---|---|
| **Control** | ISM-1569, ISM-0873 |
| **Layer** | 1 — AWS |
| **Objects examined** | `docs/assessment/matrix.yaml`, SSP §1.5, CMP §7 |
| **Method** | Examine |

**Observed.** Inheritance is recorded as the string `aws-irap-2026`, with no report version,
assessment date, assessor identity, scope statement or reassessment due date. The CMP
defines a process for re-pinning the **ISM release** but none for re-pinning the **AWS
report**.

**Expected.** An inherited control set is referenced to a specific, dated report whose scope
can be examined, with a defined review trigger.

**Potential impact.** Currency, scope and change cannot be determined from the system's own
documentation. Should AWS's assessed scope change at reassessment, no process would surface
the delta, and controls believed inherited could silently cease to be.

**Assessor note.** The entity demonstrably knows how to pin an external dependency: the
`region-deny` policy records its source list as vendored from AWS's maintained Control Tower
list and dated 2026-07-20. That standard has not been applied to the single largest external
dependency in the system.

**Recommendation.** Consider pinning the AWS report reference with the same rigour applied
to the ISM release, and adding a review trigger to the CMP.

---

## FIND-A02

**Service-by-Region assessed scope is not confirmed**

| | |
|---|---|
| **Control** | ISM-1395, ISM-1569 |
| **Layer** | 1 — AWS |
| **Objects examined** | SSP §1.5, ADR-0005, `live/` service usage |
| **Method** | Examine |

**Observed.** No examined object confirms that the AWS services this architecture depends on
are within AWS's assessed scope, in each Region used. Services warranting confirmation
include Security Lake, Cloud WAN, AWS Security Incident Response, Detective, Resource
Explorer and account Region management.

ADR-0005 acknowledges that Melbourne's service catalogue has historically lagged Sydney's,
and gates workloads on service *availability* in both Regions. No examined object addresses
service *assessed status* by Region.

**Expected.** Inherited controls are claimed only for services and Regions within the
provider's assessed scope.

**Potential impact.** A service in scope for `ap-southeast-2` but not `ap-southeast-4` would
create an inheritance gap in the Region the continuity posture depends on — precisely where
the entity would rely on it during a Sydney loss.

**Recommendation.** Consider maintaining a service-by-Region confirmation against AWS's
assessed scope, reviewed when AWS reassesses.

---

## FIND-K11

**Tenant data backup responsibility is unassigned**

| | |
|---|---|
| **Control** | ISM-1808 |
| **Layer** | 2 / 3 — boundary |
| **Outcome** | **Ineffective** |
| **Objects examined** | SSP §1.5, §19.5, ADR-0005, `replica.tf` |
| **Method** | Examine |

**Observed.** The Object-Locked archive and its replica address **log** durability. ADR-0005
addresses **service** continuity. No examined object addresses backup or restoration of
tenant data, and the SSP §1.5 responsibility table does not assign it.

**Expected.** Backup and restoration responsibility is assigned, and restoration is tested.

**Potential impact.** A responsibility absent from the shared responsibility model may be
assumed by neither party. Restoration capability for tenant data is consequently
unestablished, including in the ransomware scenario the Essential Eight backup mitigation
addresses.

**Recommendation.** Consider assigning this explicitly in the responsibility model, whether
to the platform or to workload owners, and defining how restoration is tested.

---

## FIND-K01

**SSP deferrals do not name the system where the control is assessed**

| | |
|---|---|
| **Control** | ISM-0027 |
| **Layer** | 2 — Kestrel |
| **Objects examined** | SSP §8, §9, §10, §12, §15, §16, §22, §23 |
| **Method** | Examine |

**Observed.** Several SSP chapters defer with statements such as *"Corporate email security
is enterprise IT's responsibility, outside this boundary."* These identify an owner but not
a system in which the control is assessed.

**Expected.** Where a control is deferred outside the boundary, the SSP identifies the system
or documentation set that covers it.

**Potential impact.** An authorising officer cannot determine whether a deferred control is
addressed anywhere. The deferral reads as scoping when it may be a gap.

**Recommendation.** Consider naming the covering system for each deferral, so the reader can
follow the control to where it is assessed.

---

## FIND-K08

**The replica key policy lacks the primary's administration/use split**

| | |
|---|---|
| **Control** | ISM-1162, ISM-0459 |
| **Layer** | 2 — Kestrel |
| **Objects examined** | `live/log-archive/replica.tf`, `main.tf` |
| **Method** | Examine |

**Observed.** `aws_kms_key.logs_replica` carries only an `AccountAdministration` statement.
The primary `logs` key carries an explicit `SecurityToolingUseOnly` statement implementing
the administration/use separation, with a documented rationale that no principal holds both.

**Expected.** Protective properties applied to a primary evidence store are applied to its
copies.

**Potential impact.** Limited in practice, as the replica is a durability copy. The
significance is structural: this is the same class of primary/replica divergence that
produced the entity's own FIND-012 on this same bucket pair. The lesson recorded there —
that equivalent care applies to every copy — has been applied to lifecycle configuration but
not to key policy.

**Recommendation.** Consider whether the reasoning behind the primary's key-policy split
applies equally to the replica.

---

## FIND-K05

**`deny-root` scope may be misread as estate-wide**

| | |
|---|---|
| **Control** | ISM-1685 |
| **Layer** | 2 — Kestrel |
| **Objects examined** | `deny-root.json`, `attachments.tf`, SSP §17 |
| **Method** | Examine |

**Observed.** The `deny-root` SCP denies all actions for root principals and is attached at
the organisation root. SCPs do not apply to the management account. The SSP describes root
custody procedurally in one location and the SCP in another.

**Expected.** Documentation does not permit a reader to infer broader coverage than a control
provides.

**Potential impact.** A reader could conclude root is denied estate-wide, including in the
management account, where in fact management-account root is governed by the procedural
controls of ADR-0002. The control is correctly implemented; the risk is misreading.

**Recommendation.** Consider stating the management-account exclusion where the SCP is
described.

---

## Observations

Observations are not control failures. They are recorded for the entity's consideration.

**OBS-01 — CloudFront edge TLS termination.** EXC-001 permits `us-east-1` CloudFront and ACM
management, with a compensating note that data at rest remains in Australian Regions. TLS
terminating at CloudFront edge locations means data in transit may be decrypted outside
Australia. The residency analysis addresses data at rest and is silent on this. Disclosed
per IRAP-AR-0019 (offshore considerations).

**OBS-02 — Config continuous types.** `AWS::EC2::Instance` and `AWS::RDS::DBInstance` are
recorded daily rather than continuously. Defensible on cost grounds; noted because an
instance created and destroyed between snapshots leaves no configuration item, increasing
reconstruction effort during investigation. CloudTrail retains the API calls.

**OBS-03 — Workflows committed disabled.** All `.github/workflows/` files carry the
`.disabled` suffix, consistent with the entity's documented staged-rollout convention.
Directed assumption A2 treats them as enabled. As presented, the pipeline gates are not
implemented, and every control depending on them would be **Ineffective**.

**OBS-04 — Security Lake subscriber least privilege.** The single-source subscriber grant is
correct least-privilege practice and revocation is a single resource deletion. Noted
positively; the inconsistency with the documented SOC role is raised separately as FIND-T05.

**OBS-05 — Corporate endpoint management underpins all access.** The access chain begins at a
managed compliant device evaluated by Conditional Access. That first link is outside the
assessment boundary and unassessed here. The scoping decision is legitimate; the dependency
warrants naming in the SSP.

---

## Positive findings (IRAP-AR-0045)

Recorded because a register listing only weaknesses misrepresents the system.

| Area | Observation |
|---|---|
| **KMS administration/use split** | The archive key policy separates administration from use such that no principal holds both. Object Lock without key-policy separation is materially weaker than it appears; few implementations address this |
| **Silence as a monitored condition** | Source-silence alarms use `treat_missing_data = "breaching"`, correctly recognising that a stopped source produces no datapoints. The trail-failure alarm deliberately does not depend on the trail |
| **Provider-independent alerting** | Silence alarms are Kestrel-owned on the stated reasoning that a provider cannot detect its own feed going quiet |
| **`log-archive` has no access path** | The account holding every log carries no permission set assignment at all |
| **Exception register with plan-time enforcement** | Exceptions cannot exist off-register and an expired exception fails the plan. This mechanism is what surfaced FIND-T03 |
| **Evidence plane independent of the SOC** | The record is Kestrel's Object-Locked archive; the provider holds a copy. Investigation does not depend on the provider's platform |
| **Vendored region-deny list** | Sourced from AWS's maintained list and dated, rather than hand-written |
| **IPv6-inclusive egress denial** | Both address families denied; IPv6 is commonly omitted |
| **Prior finding remediation** | FIND-012's fix added the missing test rather than only the missing configuration |
