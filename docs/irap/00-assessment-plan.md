# 00 — Assessment Plan

> **NOT AN IRAP ASSESSMENT.** The author is not an ASD-endorsed IRAP assessor. This is a
> simulated assessment written as a self-critique exercise. See [README](README.md).

| Field | Value |
|-------|-------|
| **System assessed** | Kestrel AWS Landing Zone |
| **Assessed entity** | Kestrel Digital Pty Ltd (fictional) |
| **Target classification** | PROTECTED |
| **ISM release** | June 2026 (`2026.06`) — latest available at commencement (IRAP-AR-0013) |
| **Framework** | IRAP Common Assessment Framework v1.0 (April 2025) |
| **Assessment degree** | **Focused** (see §2.4) |
| **Assessment date** | 26 July 2026 |
| **Report version** | 1.0 |

---

## 1. Scope

### 1.1 The assessment boundary (IRAP-AR-0018)

The landing zone as defined in [SSP §1.2](../security/system-security-plan.md#12-system-boundary):

- The AWS Organization, OU tree, and the four core accounts (`management`, `log-archive`,
  `security-tooling`, `shared-services`)
- Organisation policy instruments — SCPs, RCPs, declarative and tag policies
- Identity: IAM Identity Center, federation from Entra ID, the elevation model
- Network: Cloud WAN, IPAM, inspection VPCs, Network Firewall, egress
- Logging and evidence: organisation CloudTrail, Config, Security Lake, the Object-Locked
  archive and its Melbourne replica
- Delivery: the repository, its gates, OIDC roles, Terraform state
- The account factory and the brownfield graduation path
- Environments: production estate only. No pre-prod, test or dev instance of the landing
  zone itself exists — workload Non-Prod accounts are *within* the boundary as managed
  objects, but the applications inside them are not

### 1.2 Out of scope, with rationale (IRAP-AR-0021)

| Excluded | Rationale |
|---|---|
| AWS infrastructure and managed-service internals | Layer 1 — covered by AWS's own IRAP assessment. Assessed here only for validity of the inheritance claim |
| Entra ID product internals | Layer 3 — separately assessed product. The **integration and its configuration** remain in scope |
| The managed SOC's Sentinel tenant | Layer 3 — the provider's own environment is outside the assessed entity's boundary. The **seam** is in scope |
| Tenant workload applications and data | Separate systems requiring their own assessments and SSPs |
| Kestrel corporate IT (endpoints, email, offices) | Outside the system boundary. Noted where a platform control depends on it (see OBS-05) |
| CyberArk platform internals | Layer 3 — no assurance artefact available. Recorded as **No visibility** |

### 1.3 Layering (per CAF "Layering IRAP assessments")

ASD's framework describes layered assessments where a system depends on preceding assessed
layers. This assessment applies that model:

```text
┌───────────────────────────────────────────────────────────────┐
│ LAYER 3 — Other entities                                      │
│ Entra ID · Managed SOC · GitHub · CyberArk · Tenant owners     │
│ Assessed: assurance position and the SEAM to Layer 2          │
└───────────────────────────────────────────────────────────────┘
              ▲                                    ▲
┌───────────────────────────────────────────────────────────────┐
│ LAYER 2 — Kestrel landing zone          ← THE ASSESSMENT      │
│ Org · policy · identity · network · logging · pipeline        │
│ Assessed: control implementation effectiveness, ISM Jun 2026  │
└───────────────────────────────────────────────────────────────┘
              ▲  utilises assessed provider components
┌───────────────────────────────────────────────────────────────┐
│ LAYER 1 — AWS (cloud infrastructure provider)                 │
│ Facilities · hypervisor · managed-service internals           │
│ NOT re-assessed. Assessed: validity of the inheritance claim  │
└───────────────────────────────────────────────────────────────┘
```

Note this pack's layer numbering differs from the CAF's illustrative example, where Layer 3
is the consuming government agency. Here Kestrel is a SaaS provider hosting agency data, so
Kestrel occupies the SaaS layer and its non-AWS dependencies are grouped as a third layer.
A consuming agency would sit above this pack as a further layer, and would leverage this
report in its own assessment.

**Deviations from common controls between services are noted per service** (IRAP-AR-0020)
in [02 — Cloud Controls Matrix](02-cloud-controls-matrix.md).

## 2. Methodology

### 2.1 Assessment stages (IRAP-AR-0012)

The CAF's four stages, and what was performed:

| Stage | CAF activity | Performed here |
|-------|--------------|----------------|
| **1 — Plan and prepare** | Notify ASD IRAP, agree logistics, conflict of interest declaration | **Not performed.** No ASD notification; no COI declaration submitted (see §6) |
| **2 — Define the boundary** | Formally define scope, assets, data flows, interconnections | Performed — §1 |
| **3 — Assess the controls** | Collect and review evidence; determine implementation effectiveness | Performed — with the method limitations in §5 |
| **4 — Produce the report** | Document boundary, system overview, strengths, weaknesses, limitations, recommendations | Performed — [01](01-security-assessment-report.md) |

### 2.2 Assessment methods (IRAP-AR-0024)

The CAF defines three methods. Their availability here was uneven, and this materially
shapes every rating:

| Method | Definition | Used |
|--------|-----------|------|
| **Examine** | Checking, inspecting, reviewing, observing or analysing assessment objects | **Yes** — extensively. Specifications (SSP, SRMP, CMP, IRP, ADRs) and mechanisms as declared in source configuration |
| **Interview** | Discussions with individuals or groups | **No.** Not available |
| **Test** | Exercising assessment objects under specified conditions to compare actual with expected behaviour | **No.** Not available |

**Consequence.** With neither Interview nor Test available, no control in this assessment
rests on better than **Fair** evidence (§2.3). Controls whose substance is procedural —
root ceremonies, drills, triage, approval workflows — have no assessable object at all and
are rated **No visibility**.

### 2.3 Quality of evidence (IRAP-AR-0026, IRAP-AR-0027)

The CAF's four-level scale, and where this assessment sits:

| Level | CAF definition | Available here |
|-------|----------------|----------------|
| **Excellent** | Examine, test or review firsthand the activities or mechanisms demonstrating the control operates | **No** |
| **Good** | Review technical configuration *through the system's interface* to determine whether it should enforce the expected policy | **No** — no console or API access |
| **Fair** | Review **a copy** of the system's configuration to determine if it should enforce the expected policy | **Yes** — this is the assessment's evidence ceiling |
| **Poor** | Statements of implementation in documents that assert the control exists | Present for procedural controls |

**The evidence ceiling is Fair.** Terraform source in a repository is a *copy of
configuration*, not the running system. Where a control's only support is a documented
assertion, evidence is **Poor** and the rating is **No visibility**.

### 2.4 Assessment degree

**Focused.** Per the CAF: high-level review plus detailed checks and inspection of
assessment objects, using a representative sample plus objects deemed particularly
important, giving a good level of assurance.

Not *Comprehensive*, which requires control testing and would need Test and Interview
methods.

### 2.5 Sampling methodology (IRAP-AR-0002)

**Method.** Judgemental (purposive) sampling — not random. 47 controls were selected across
all 22 ISM guidelines.

**Selection criteria.** Controls were prioritised where they were load-bearing for the
system's own claims (logging, cryptography, identity), where the layer boundary was
contested, where the assessed entity's documentation disclosed a known gap, and where
Essential Eight mitigations apply to a cloud consumer.

**Advantages.** Concentrates effort on controls most likely to be materially weak or
contested; efficient given the boundary's size; well suited to a design-level review.

**Disadvantages, stated plainly.** Judgemental sampling is **not statistically
representative** and cannot support extrapolation to the unsampled population. It carries
selection bias — controls were chosen partly because the assessor expected them to be
interesting. Approximately 1,054 applicable controls in the June 2026 release were **not
assessed** and are recorded as **Not assessed**, not as effective. A conclusion about the
system's overall posture cannot be drawn from this sample alone.

**Why chosen.** A census was not achievable within the assessment's method limitations, and
a random sample of 47 from ~1,101 would have produced weaker insight per control assessed
while still being non-representative at that sample size.

### 2.6 Implementation outcome terminology (IRAP-AR-0003)

ASD's standardised terminology is used exactly. **"Partially effective" is not an ASD term
and is not used in this pack.**

| Outcome | Meaning |
|---------|---------|
| **Effective** | The control implementation effectively meets the intent of the ISM control objective |
| **Ineffective** | The control implementation does not adequately meet the intent of the ISM control objective |
| **Alternate control** | The intent is met through an alternate control, supported by sufficient evidence |
| **Not assessed** | The control has not yet been assessed |
| **Not applicable** | The control does not apply to this system or environment |
| **No visibility** | Adequate visibility or assurance of the control's implementation could not be obtained. **Authorising officers may treat this as ineffective from a risk perspective** |
| **Not implemented** | The control has not been implemented, generally due to a business or technical constraint — recorded with that decision or constraint |

Every outcome, including *Not applicable* and *Not implemented*, carries an assessor
justification.

## 3. Assessment objects examined (IRAP-AR-0024, IRAP-AR-0001)

| Object | Type | Evidence quality |
|--------|------|------------------|
| [SSP](../security/system-security-plan.md) | Specification | Poor–Fair |
| [SRMP](../security/security-risk-management-plan.md) | Specification | Poor–Fair |
| [CMP](../security/continuous-monitoring-plan.md) | Specification | Poor–Fair |
| [IRP](../security/incident-response-plan.md) | Specification | Poor–Fair |
| [`matrix.yaml`](../assessment/matrix.yaml) | Specification | Fair |
| [`docs/assessment/findings/`](../assessment/findings/) | Activity record | Fair |
| [`docs/adr/`](../adr/) | Specification | Fair |
| [`live/`](../../live/), [`modules/`](../../modules/), [`bootstrap/`](../../bootstrap/) | Mechanism (declared) | Fair |
| [`live/management/policies/*.json`](../../live/management/policies/) | Mechanism (declared) | Fair |
| [`exceptions.yaml`](../../live/management/policies/exceptions.yaml) | Mechanism + activity | Fair |
| [`policy/`](../../policy/) | Mechanism (declared) | Fair |
| [`.github/workflows/`](../../.github/) | Mechanism (declared, disabled) | Poor |
| Personnel | — | **Not available** |
| Running estate | — | **Not available** |

Full detail: [07 — Evidence register](07-evidence-register.md).

## 4. Prior assessments (IRAP-AR-0019)

No prior IRAP assessment of this system exists. The assessed entity has conducted an
internal self-assessment ([`docs/assessment/`](../assessment/)) which was examined. Its one
closed finding (FIND-012, log replica retention) was reviewed and the remediation confirmed
present in [`live/log-archive/replica.tf`](../../live/log-archive/replica.tf). Its one open
finding (FIND-019, application control) is carried forward into this assessment.

## 5. Constraints and limitations (IRAP-AR-0006, IRAP-AR-0005)

### 5.1 Directed assumptions — and their conflict with IRAP-AR-0040

Two assumptions were directed by the assessed entity. **IRAP-AR-0040 requires that the
assessor base the assessment on presented evidence and facts and not make inappropriate
assumptions, and IRAP-AR-0023 requires assessing only what is implemented, not what will
be.** These directed assumptions are a departure from both, declared here rather than
concealed.

**A1 — The estate is assumed deployed and operating**, with evidence objects under
`s3://kestrel-log-archive/irap/phase-<n>/` assumed to exist and resolve. **No such object
was sighted.**

> **Assessor position.** In a genuine assessment this assumption would not be granted. An
> evidence path that cannot be resolved is not a gap to be assumed away — the control would
> be rated **No visibility**. Ratings of *Effective* in this pack therefore mean *"the
> declared configuration would meet the control's intent if deployed as written"*. They are
> not statements that the control was observed operating.

**A2 — CI/CD workflows are assumed enabled.** All workflows are committed as
`*.yml.disabled`.

> **Assessor position.** As presented, the pipeline gates are **not implemented**. Under A2
> they are assessed on their declared definitions. Absent A2, every control depending on a
> pipeline gate is **Ineffective** — a gate that does not execute is not a gate. Recorded as
> **OBS-03**.

### 5.2 Method limitations and their impact

| Limitation | Impact on the assessment |
|---|---|
| **No Interview method** | Procedural controls (root ceremony and two-person rule, quarterly drills, SOC triage, PIM approval) have no assessable object → **No visibility** |
| **No Test method** | No control was exercised to compare actual against expected behaviour. Evidence ceiling is Fair |
| **No live estate access** | Drift between declared configuration and running state is undetectable. Configuration is a *copy*, not the system |
| **No AWS IRAP report** | Layer 1 inheritance assessed for logical validity only, not against AWS's actual assessed service and Region scope |
| **No third-party assurance artefacts** | Entra ID, SOC, GitHub and CyberArk assessed from the assessed entity's description of those relationships |
| **Judgemental sample of 47** | ~1,054 applicable controls **Not assessed** |
| **Fictional system, placeholder identifiers** | Nothing requiring a real identifier could be verified |

### 5.3 The overriding limitation

**The author is not an ASD-endorsed IRAP assessor** and no Conflict of Interest declaration
was submitted to ASD IRAP. No finding, rating or statement in this pack carries the weight
of an IRAP assessment outcome.

## 6. Conflict of interest (IRAP-AR-0008, 0009, 0010, 0011)

The CAF requires a COI declaration submitted to ASD IRAP at least 7 business days before
commencement, maintained throughout, with all conflicts disclosed to authorising officers.

**Declared conflict — material and disqualifying.** The author of this assessment also
authored the [`docs/security/`](../security/) documentation set being assessed, in the same
working session. This is a direct self-assessment conflict. An IRAP assessor in this
position would be required to decline the engagement.

**Mitigation applied**, which does not cure the conflict: the assessment was conducted
adversarially by direction, seeking to falsify rather than confirm the documentation's
claims, and findings are raised against documents the author wrote — including two findings
of the highest severity assigned in this pack.

**No COI declaration was submitted to ASD IRAP**, as no IRAP engagement exists. Recorded
here to satisfy the *intent* of IRAP-AR-0011 (conflicts disclosed to authorising officers).

## 7. Statements this pack does not make (IRAP-AR-0041)

Per IRAP-AR-0041, an IRAP assessor does not use statements of compliance, conformity,
certification or authorisation — such statements undermine the report's ability to support
a risk-based authority-to-operate decision.

Accordingly this pack does **not** state that the system is compliant, certified,
accredited, or authorised to operate, and does **not** recommend that it be authorised.
Those determinations belong to the authorising officer.

Similarly, per IRAP-AR-0034, this pack **articulates potential impact but does not rate
risks** on the assessed entity's behalf. Findings carry an impact statement; the risk rating
belongs in Kestrel's own [SRMP](../security/security-risk-management-plan.md).

## 8. Report structure

| Document | Contents |
|----------|----------|
| [01 — Security Assessment Report](01-security-assessment-report.md) | Boundary, system overview, strengths, weaknesses, limitations, shared responsibility |
| [02 — Cloud Controls Matrix](02-cloud-controls-matrix.md) | 47 controls: outcome, assessment objects, methods, justification |
| [03 — Findings register](03-findings-register.md) | Weaknesses with observed vs expected and potential impact |
| [04 — Layer 1](04-layer-1-aws.md) | AWS inheritance validity |
| [05 — Layer 2](05-layer-2-kestrel.md) | Kestrel's controls by ISM guideline |
| [06 — Layer 3](06-layer-3-third-parties.md) | Third parties and inter-layer seams |
| [07 — Evidence register](07-evidence-register.md) | Objects examined, quality, and gaps |
| [08 — Recommendations](08-recommendations.md) | Descriptive recommendations (IRAP-AR-0033) |
| [09 — IRAP-AR conformance](09-irap-ar-conformance.md) | This pack against all 46 requirements |
