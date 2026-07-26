# 04 — Layer 1: Amazon Web Services

> **NOT AN IRAP ASSESSMENT.** The author is not an ASD-endorsed IRAP assessor. See
> [README](README.md).

**Layer purpose.** AWS is not re-assessed here — it holds its own IRAP assessment. What is
assessed is whether **Kestrel's claim to inherit** AWS's controls is valid: the right
services, the right regions, a current report, and no control claimed as inherited that
AWS does not actually provide.

**Overall layer observation.** The inheritance model is soundly conceived and better
articulated than most consumer systems achieve. Two weaknesses limit the assurance
available: the inheritance reference is unversioned and undated, and services central to
the architecture require confirmation that they fall within AWS's assessed scope. Per-control
outcomes are recorded in the [controls matrix](02-cloud-controls-matrix.md).

---

## 1. What Kestrel claims to inherit

From [SSP §1.5](../security/system-security-plan.md#15-shared-responsibility-cloud-controls-matrix-ism-1569) and
`matrix.yaml`:

```yaml
inherited: aws-irap-2026   # controls evidenced by AWS's own report, listed by ref
```

| Claimed inherited | SSP section |
|---|---|
| Physical facilities, personnel, environmental controls | §6, §7, §12 |
| Hypervisor and virtualisation isolation (Nitro) | §18 |
| Media sanitisation and destruction | §13 |
| Communications infrastructure | §8 |
| Managed-service internals | §1.5 |
| Cryptographic module validation (KMS, FIPS 140-3) | §11, §25 |

## 2. Assessment

### 2.1 The inheritance reference is unversioned — **FIND-A01**

`matrix.yaml` records the inheritance as the bare string `aws-irap-2026`. That identifier
carries no report version, no assessment date, no assessor name, and no scope statement.

**Why this matters at PROTECTED.** An inherited control is only as good as the report
behind it, and reports have boundaries. Without a versioned reference, three questions
cannot be answered from the system's own documentation:

1. **Currency.** ASD guidance is that CSPs should be reassessed at least every 24 months.
   Is the report Kestrel relies on inside that window?
2. **Scope.** Which services and which regions did AWS's assessor actually assess?
3. **Delta.** When AWS reassesses, what changed, and does anything Kestrel inherits move?

The system owner's own rule — *"a claim with no existing evidence object is a finding"* —
applies to this claim and is not met by it. The CMP has a mature process for re-pinning
the **ISM** release ([CMP §7](../security/continuous-monitoring-plan.md#7-ism-release-change-management))
but no equivalent for re-pinning the **AWS report**, which is the same class of dependency.

**Expected.** A pinned, dated reference — report title, version, assessment date, assessor,
assessed scope, and the next reassessment due date — with a review trigger in the CMP.

**Assessor position.** The controls are very likely genuinely inherited; the *claim* is not
evidenced to the standard the rest of the pack sets for itself. ISM-1569 remains Effective on
the strength of the responsibility documentation, but this weakness is recorded against it.

### 2.2 Service scope confirmation — **FIND-A02**

The architecture depends on services whose presence in AWS's assessed scope must be
confirmed rather than presumed. Consumers routinely assume "AWS is IRAP assessed" means
every service is in scope; it does not — assessment covers an enumerated service list, and
newer services frequently lag.

Services this system makes load-bearing use of, flagged for scope confirmation:

| Service | Role in the architecture | Note |
|---|---|---|
| **Amazon Security Lake** | The OCSF evidence normalisation layer and SOC seam | Relatively recent; confirm assessed scope in both Regions |
| **AWS Cloud WAN** | The entire network fabric | Confirm; Transit Gateway was the rejected alternative and has longer assessment history |
| **AWS Security Incident Response** | Case management target in `findings.tf` | Recent service; confirm |
| **Amazon Detective** | Forensic capability relied on by the IRP | Confirm |
| **AWS Account Region management** (`aws_account_region`) | Used by the baseline to opt into `ap-southeast-4` | Confirm |
| **Resource Explorer** | Underpins the coverage query — the CMP's zero-gaps criterion | Confirm |

**Melbourne (`ap-southeast-4`) is the sharper question.** The estate is active-active
across both Australian Regions ([ADR-0005](../adr/ADR-0005-region-posture.md)), and
ADR-0005 itself acknowledges Melbourne's service catalogue has historically lagged
Sydney's. A service assessed in `ap-southeast-2` is not automatically assessed in
`ap-southeast-4`. Any service in the table above that is in scope for Sydney but not
Melbourne creates an inheritance gap **precisely in the Region the continuity claim depends
on**.

ADR-0005 addresses the *availability* of services by Region with a gate ("a workload may
only land in a zone whose services exist in both Regions"). It does not address the
*assessed status* of those services by Region. Those are different questions and the
second is not asked anywhere in the pack.

**Expected.** A service-by-service, Region-by-Region confirmation against AWS's assessed
scope, maintained as an artefact and reviewed on each AWS reassessment.

### 2.3 The consumer-side configuration of inherited controls — **Effective**

A common and serious consumer error is to inherit a control while configuring the service
in a way that defeats it. This system does not make that error, and several places show
active thought about it:

| Inherited capability | Consumer configuration | Assessment |
|---|---|---|
| KMS FIPS-validated modules | Customer-managed keys, annual rotation, **admin/use split so no principal holds both** | **Effective.** Exceeds typical practice — the split is the control that makes rotation meaningful |
| S3 durability and Object Lock | COMPLIANCE mode, 7 years, set at bucket creation, `prevent_destroy` in Terraform | **Effective.** COMPLIANCE over GOVERNANCE is the correct choice and correctly justified |
| CloudTrail integrity | `enable_log_file_validation = true` — digest files | **Effective** |
| Regional isolation | `region-deny` SCP with the carve-out list **vendored from AWS's maintained Control Tower list, not hand-written** | **Effective.** The reasoning is sound: a hand-written list omits a service and produces an outage |
| Nitro tenant isolation | One account per tenant in Prod — isolation at the account boundary, the strongest primitive AWS offers | **Effective** |

The `region-deny` provenance note deserves specific credit: it is dated (read 2026-07-20)
and sourced. That is the standard the AWS report reference in §2.1 should meet and does
not — the system demonstrably knows how to pin an external dependency properly, and simply
has not applied that discipline to the report itself.

### 2.4 Data residency — **Effective, with one observation**

Residency is enforced structurally rather than asserted:

- `region-deny` SCP at the organisation root restricts operations to Australian Regions
- Cross-Region replication targets `ap-southeast-4`, explicitly commented *"stays onshore —
  evidence never leaves the residency boundary"*
- Terraform state is self-managed in-boundary; HCP Terraform was rejected for having no
  Australian Region ([ADR-0003](../adr/ADR-0003-engine-and-state.md))

The state decision is a genuinely good catch — state files contain resource configuration
and occasionally provider-generated secrets, and consumers frequently overlook that SaaS
state backends are a residency break irrespective of encryption.

**Observation (OBS-01).** `EXC-001` in the exception register permits CloudFront
certificate and web ACL management in `us-east-1`. The register's compensating-control note
("ACM and WAF actions only; data residency unaffected — TLS terminates at the edge, data at
rest stays in Australian Regions") is technically correct and correctly scoped.

However, TLS terminating at a CloudFront edge means **PROTECTED data in transit is
decrypted at edge locations that may sit outside Australia**. The exception is registered
with owner, reason, compensating control and expiry — the register mechanism works exactly
as designed. What is missing is that the residency analysis addresses data *at rest* and is
silent on data *in transit at the edge*. This warrants an explicit position rather than
being left implied.

### 2.5 Inheritance the system correctly declines to claim — **Effective**

Assessed positively, because over-claiming is the more common failure:

- AWS's IRAP status is not used to claim controls Kestrel is responsible for configuring
- [SSP §1.5](../security/system-security-plan.md#15-shared-responsibility-cloud-controls-matrix-ism-1569)
  states: *"Kestrel does not claim a control merely because AWS offers a capability — the
  claim is that the capability is configured and proven in this estate."* That is the
  correct posture, stated explicitly
- Guest OS hardening, application control and patching are pushed to the workload owner
  rather than absorbed into the platform's claims
- ISM-1569 (provider/consumer responsibility documentation) is genuinely addressed, where
  most consumer systems leave the ASD template's columns blank

## 3. Layer 1 findings

| Ref | Finding | Potential impact area |
|-----|---------|----------------------|
| **FIND-A01** | Moderate | AWS IRAP report reference is unversioned and undated; no re-pinning process exists |
| **FIND-A02** | Moderate | Service-by-Region assessed-scope confirmation not performed, notably for `ap-southeast-4` |
| **OBS-01** | Observation | CloudFront edge TLS termination outside Australia not addressed in the residency position |

## 4. Layer 1 rating

**Observation.** The consumer-side configuration of inherited capability is genuinely strong — the KMS
admin/use split, COMPLIANCE Object Lock, vendored region-deny list and in-boundary state
all show a team that understands what inheritance does and does not give them.

The rating is held below Effective by the **provenance of the inheritance claim itself**.
The pack holds every internal claim to a documented, dated, machine-reconciled standard;
the single largest external dependency is referenced by a bare string. That asymmetry, not
any control weakness, is the Layer 1 finding.
