# 02 — Cloud Controls Matrix

> **NOT AN IRAP ASSESSMENT.** The author is not an ASD-endorsed IRAP assessor. Outcomes
> below carry no assessment weight. See [README](README.md).

**Audience:** technical personnel and system administrators (per CAF minimum deliverables).

| Field | Value |
|-------|-------|
| **ISM release** | June 2026 (`2026.06`) |
| **Classification** | PROTECTED |
| **Controls sampled** | 47 of ~1,101 — judgemental sample, see [00 §2.5](00-assessment-plan.md#25-sampling-methodology-irap-ar-0002) |
| **Assessment degree** | Focused |
| **Evidence ceiling** | **Fair** — copies of configuration; no Test or Interview method available |

## Terminology (IRAP-AR-0003)

ASD's standardised outcomes are used. **"Partially effective" is not an ASD term and does
not appear in this matrix.**

`Effective` · `Ineffective` · `Alternate control` · `Not assessed` · `Not applicable` ·
`No visibility` · `Not implemented`

**`No visibility`** means adequate assurance could not be obtained. Per the CAF,
**authorising officers may treat this as ineffective from a risk perspective.**

## Methods (IRAP-AR-0024)

`E` = Examine · `I` = Interview (**unavailable**) · `T` = Test (**unavailable**)

Every control below was assessed by **Examine only**. No control was tested. This is the
single most important qualifier on this matrix.

**Layer:** 1 = AWS · 2 = Kestrel · 3 = Third party · S = Shared

---

## Summary of outcomes

| Outcome | Count | Note |
|---------|-------|------|
| **Effective** | 21 | Declared configuration meets control intent (subject to A1/A2) |
| **Ineffective** | 3 | |
| **No visibility** | 15 | Procedural or third-party controls with no assessable object |
| **Not implemented** | 1 | With the entity's recorded business decision |
| **Not applicable** | 2 | |
| **Alternate control** | 1 | |
| **Not assessed** | 4 | Claimed by the entity; substance outside the examinable boundary |
| **Total sampled** | **47** | |

**~1,054 applicable controls were not sampled and are Not assessed.** No conclusion about
the unsampled population may be drawn from this matrix.

---

## Cyber security documentation

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-0047 | Security documentation maintained and reviewed | 2 | E | **Effective** | Objects: SSP, SRMP, CMP, IRP. All present, version-controlled, PR-gated, annual review cycle defined. Meets intent |
| ISM-1569 | Cloud provider/consumer responsibilities documented | S | E | **Effective** | Object: SSP §1.5. Responsibility split completed per layer, including where consumer declines to claim inherited capability. Meets intent; exceeds typical practice |
| ISM-0027 | SSP developed and maintained | 2 | E | **Effective** | Object: SSP. Structure follows ASD Blueprint SSP; boundary, architecture and data flows articulated. FIND-K01 notes deferral precision but does not defeat intent |
| ISM-1163 | SRMP developed and maintained | 2 | E | **Effective** | Object: SRMP. 13 risks, inherent→residual, acceptance authority by band, expiries recorded |

## Cyber security roles

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-0714 | CISO appointed | 2 | E | **No visibility** | Object: SSP §2 (specification only). Role named; appointment not evidenced. Interview unavailable |
| ISM-1071 | System owner registered and accountable | 2 | E | **No visibility** | As above |
| GOV-11 | Supplier assurance regularly independently verified | 3 | E | **Ineffective** | Objects: SSP §4, exceptions register. AWS/Microsoft assessed; **GitHub and CyberArk carry no assurance artefact** despite control-plane and credential-custody criticality. Does not adequately meet intent — FIND-T04, FIND-T06 |
| GOV-12 | Ongoing personnel suitability assurance | 3 | E | **No visibility** | Policy asserted in SSP §7. No HR record examinable; interview unavailable |

## Personnel security

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-0434 | Personnel vetted appropriately | 3 | E | **No visibility** | Vetting asserted as an Entra group precondition. No AGSVA or HR record examinable |
| ISM-2104 | Personnel restricted from posting about clearances | 3 | E | **No visibility** | New Jun-2026. Policy asserted; acknowledgement records not examinable |
| ISM-2105–2107 | Personnel restricted from posting duties/skills/experience | 3 | E | **No visibility** | As above. Entity correctly declares no technical enforcement point exists |

## Physical security

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-1053 | Facilities appropriately secured | 1 | E | **Not applicable** | To the assessed entity: no Kestrel-operated facility is in boundary. Data centre controls are AWS's, covered by AWS's own assessment. Kestrel-side safes (ADR-0002) assessed under ISM-1685 |

## Authentication hardening

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-1173 | MFA for privileged access | 3 | E | **No visibility** | Enforced in Entra ID. No tenant configuration export examinable |
| ISM-1175 | Privileged access requested, approved, time-bound, logged | 3 | E | **No visibility** | Object: `live/identity/`. AWS side confirms JIT groups hold no standing grant. **The approval workflow is in Entra PIM; no configuration export exists** — FIND-T01. Entity claims this control as met in `matrix.yaml` |
| ISM-1507 | Separate privileged accounts | 2 | E | **Effective** | Object: `assignments.tf`. `sg-aws-*-jit` groups appear in no standing grant; PIM-populated only during activation. Declared configuration meets intent |
| ISM-1380 | Privileged access limited to what is required | 2 | E | **Ineffective** | Object: `permission-sets.tf`. `WorkloadDeploy` = `PowerUserAccess` as a standing group grant. Breadth is not limited to requirement at PROTECTED; flip condition is unenforceable — FIND-K03 |
| ISM-0445 | Privileged accounts prevented from internet/email | 2 | E | **Effective** | Objects: `network-denies.json`, SSP §10. No workload egress path; admin access requires managed device |
| ISM-1503 | Standard access limited to what is required | 2 | E | **Effective** | Object: `assignments.tf`. OU-derived; `log-archive` deliberately carries no assignment block |
| ISM-1546 | Users uniquely identifiable | 2 | E | **Effective** | Federated identities; no shared accounts in configuration. Break-glass is a documented exception under ISM-1685 |
| ISM-0421 | Credential requirements enforced | 3 | E | **No visibility** | Entra ID. No configuration export |
| ISM-1685 | Break-glass accounts controlled | 2 | E | **No visibility** | Object: ADR-0002 (specification). Design articulates CyberArk custody, dual FIPS tokens, two-person rule, quarterly drills. **No drill record, checkout log or ceremony observation examinable** — FIND-K04 |

## System monitoring

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-0580 | Event logging centralised, protected from modification | 2 | E | **Effective** | Object: `log-archive/main.tf`. Object Lock COMPLIANCE 7y set at creation, versioning, `prevent_destroy`, service-only writers scoped by `aws:SourceOrgID`, log file validation. Declared configuration meets intent |
| ISM-0859 | Event logs retained per disposal authority | 2 | E | **Effective** | Objects: `main.tf`, `replica.tf`. Two aligned clocks (365d Glacier, 2555d expiry) on primary and replica. Prior FIND-012 remediation confirmed present |
| ISM-1988 | Logs searchable 12 months | 2 | E | **Effective** | Hot in S3 Standard 365 days; Athena configured |
| ISM-0988 | Common time source | 2 | E | **Not assessed** | Entity claims this control with evidence `phase-04/time-sync-attestation.json`. **No time-synchronisation configuration found in any examined object.** Cannot be assessed from available objects |
| ISM-1405 | Event log details captured | 2 | E | **Effective** | Object: `trail.tf`. Management, Data and NetworkActivity categories configured |
| ISM-0585 | Privileged operation events logged | 2 | E | **Effective** | Organisation trail, all accounts, multi-Region |
| ISM-1906 | Security events analysed in a timely manner | 2 | E | **No visibility** | Object: `findings.tf`. Routing design examinable and sound. **Whether events are analysed — pages answered, SLA met — requires records and interview.** Compounded by FIND-K10 (no alerting-path redundancy) and FIND-T05 (SOC scope) |
| ISM-0109 | Data access events logged | 2 | E | **Ineffective** | Object: `trail.tf`. Data events scoped by bucket-name prefix `kestrel-protected-`. **No examined object enforces that naming convention**, so coverage depends on an unenforced habit. Does not adequately meet intent — FIND-K02 |
| ISM-1228 | Anomalous activity detected | S | E | **Effective** | GuardDuty, Security Hub, Macie, Access Analyzer configured org-wide via delegated admin |

## Cryptography

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-0459 | Keys managed and rotated | 2 | E | **Effective** | Object: `main.tf` key policy. CMK, annual rotation, and an administration/use split in which no principal holds both. Exceeds the control's minimum intent |
| ISM-1139 | TLS 1.2+ with approved algorithms | 2 | E | **Effective** | Object: bucket policy `DenyInsecureTransport`. Declared configuration meets intent for the archive. Estate-wide TLS posture rests on claimed evidence (A1) |
| ISM-0467 | Approved cryptographic algorithms | 1 | E | **Effective** | Inherited from AWS KMS (FIPS 140-3). Consumer configuration uses AWS-managed algorithm selection |
| ISM-1162 | Data at rest encrypted | 2 | E | **Effective** | SSE-KMS throughout. Replica key lacks the primary's admin/use split (FIND-K08) — a weakness noted, not sufficient to defeat intent |

## Network hardening

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-1181 | Network segmentation and segregation | 2 | E | **Effective** | Objects: `core-network-policy.tf`, ADR-0005. Segment per zone; peering link carries no default route; account-boundary tenant isolation |
| ISM-1182 | Network traffic filtered | 2 | E | **Ineffective** | Object: `firewall.tf`. Allow-list includes `.amazonaws.com` and `.github.com`, permitting egress to arbitrary third-party S3 buckets and repositories. For a system naming insider exfiltration as its primary threat, this does not adequately meet intent — FIND-K06 |
| ISM-0520 | Gateway controls all traffic | 2 | E | **Effective** | Object: `network-denies.json`. IGW denied in IPv4 and IPv6; single inspected egress per Region |
| ISM-1428 | Data perimeter / egress controls | 2 | E | **Alternate control** | Objects: `org-perimeter.json`, `resource-perimeter.json`. The intent — preventing unauthorised data egress — is met through an org-boundary perimeter rather than conventional DLP. Supported by sufficient evidence for the four services enumerated. **Coverage gaps** (`logs`, `sns`, `ssm`, `ecr`) are recorded as FIND-K09 |
| ISM-1195 | Network access controls | 2 | E | **Effective** | IPAM-only VPC creation; `Null` condition denies `CreateVpc` with no pool specified |

## System management

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-1526 | Changes travel a reviewed, gated pipeline | 2 | E | **No visibility** | Objects: `.github/workflows/*.yml.disabled`, CODEOWNERS. **Workflows are committed disabled.** Under directed assumption A2 the definitions are sound; as presented, no gate executes. Assurance of operation unobtainable — OBS-03 |
| ISM-1493 | Standard operating environment | 2 | E | **Effective** | Object: `modules/account-baseline/`. Idempotent baseline that doubles as the brownfield graduation checklist — one path, not two |
| ISM-1690 | Patching within timeframes | S | E | **No visibility** | Windows defined in SSP §14 and CMP §5; Inspector configured. **Execution is the workload owner's; no remediation record examinable** |
| ISM-1704 | Vulnerability scanning | 2 | E | **Effective** | Inspector configured org-wide, continuous |
| ISM-0140 | System hardening | S | E | **No visibility** | Platform layer strong (no persistent OS in the landing zone). Guest OS hardening is the workload owner's; no tenant object examinable |
| ISM-1808 | Backups performed and tested | 2 | E | **Ineffective** | Log archive replicated cross-Region. **No examined object addresses backup or restoration of tenant data, and no document assigns that responsibility** — FIND-K11. Restoration testing not evidenced |

## Procurement and outsourcing

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-0873 | Outsourced services meet security requirements | 3 | E | **Ineffective** | Object: SSP §4. AWS, Microsoft and the SOC governed. GitHub and CyberArk carry no assurance position despite Critical criticality — FIND-T04, FIND-T06 |
| ISM-1395 | Data sovereignty maintained | S | E | **Effective** | Objects: `region-deny.json`, ADR-0003, `replica.tf`. Australian Regions enforced at org root; state in-boundary; replica onshore. **Offshore exposure: EXC-001 permits `us-east-1` CloudFront/ACM management, and edge TLS termination may occur outside Australia** — OBS-01, disclosed per IRAP-AR-0019 |

## Cyber security incidents

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-0576 | Incident response plan exists | 2 | E | **Effective** | Object: IRP. Severity model, routing, five phases, six playbooks, notification obligations |
| ISM-0140b | Incidents reported to ASD | 2 | E | **No visibility** | Process defined in IRP §7. No incident record examinable |
| ISM-1819 | Incident response exercised | 2 | E | **No visibility** | Quarterly drills and six-monthly tabletops defined in IRP §9. **No drill record examinable; interview unavailable** |

## User application hardening

| Control | Intent | Layer | Method | Outcome | Assessment objects & justification |
|---|---|---|---|---|---|
| ISM-1553 | Application control enforced | 3 | E | **Not implemented** | **Business decision recorded by the entity:** disclosed as FIND-019 with owner `platform-team` and expiry 2026-12-01. Compensating controls asserted (managed-device Conditional Access, no credential usable from unmanaged endpoints, Session Manager–only instance access). Essential Eight ML1 mitigation absent |
| ISM-1486 | Web content filtering | 2 | E | **Not applicable** | No user web browsing occurs within the assessment boundary; the landing zone hosts no user workstations |
| ISM-0345 | Email content filtering | 2 | E | **Not applicable** | The system sends no user email. Account contact addresses are monitored distribution lists outside the boundary |

---

## Deviations from the entity's own control matrix (IRAP-AR-0020)

| Control | Entity's position | This assessment | Basis for the deviation |
|---|---|---|---|
| ISM-1175 | Claimed met, evidence `phase-07/elevation-lifecycle-battery.json` | **No visibility** | The evidence covers the AWS-side assignment. The approval workflow, approver set and activation limits reside in Entra PIM, for which no configuration object exists in any examined artefact |
| ISM-0988 | Claimed met, evidence `phase-04/time-sync-attestation.json` | **Not assessed** | No time-synchronisation configuration appears in any examined object |
| ISM-0109 | Implied met by trail configuration | **Ineffective** | Scoping depends on a bucket-naming convention that no examined object enforces |
| ISM-1526 | Claimed met, evidence `phase-02/pipeline-end-to-end-run.json` | **No visibility** | Workflows are committed disabled |
| ISM-0459 | Claimed met | **Effective** | Agreed. The administration/use key-policy split exceeds the control's minimum intent |
| ISM-1507 | Claimed met | **Effective** | Agreed, verified in declared configuration |

The entity's matrix is accurate where its claims rest on objects within the AWS estate. The
deviations cluster where a claimed control's **substance sits outside that estate** — the
class of gap a layered assessment exists to surface.
