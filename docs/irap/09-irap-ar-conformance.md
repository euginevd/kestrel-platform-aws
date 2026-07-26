# 09 — Conformance against the 46 IRAP Assessment Requirements

> **NOT AN IRAP ASSESSMENT.** The author is not an ASD-endorsed IRAP assessor. See
> [README](README.md).

**Source:** [IRAP Common Assessment Framework v1.0, April 2025](https://www.cyber.gov.au/sites/default/files/2025-04/IRAP%20common%20assessment%20framework.pdf),
Appendix B — Assessment requirements matrix. Requirements **IRAP-AR-0001** to
**IRAP-AR-0046**, grouped into seven quality standards.

This document states, requirement by requirement, where this pack conforms, partially
conforms, or **cannot** conform. The last category is significant: several requirements
presuppose a registered assessor conducting a genuine engagement, and no amount of careful
writing can satisfy them here.

## Summary

| Status | Count | Meaning |
|--------|-------|---------|
| **Conforms** | 28 | The requirement's intent is met by this pack |
| **Partially conforms** | 9 | Met in substance but with a stated shortfall |
| **Cannot conform** | 9 | Requires a registered assessor or a real engagement |

---

## Quality standard 1 — Report quality and terminology

| Req | Requirement | Status | Where / why |
|-----|-------------|--------|-------------|
| **0003** | Uses correct ASD terminology and intent for control implementation | **Conforms** | ASD's exact outcomes used throughout: Effective, Ineffective, Alternate control, Not assessed, Not applicable, No visibility, Not implemented. "Partially effective" — used in an earlier draft — was removed as it is not an ASD term. [02](02-cloud-controls-matrix.md), [00 §2.6](00-assessment-plan.md#26-implementation-outcome-terminology-irap-ar-0003) |
| **0006** | Clearly articulates constraints and limitations, and their impacts | **Conforms** | [00 §5](00-assessment-plan.md#5-constraints-and-limitations-irap-ar-0006-irap-ar-0005), [01 §8](01-security-assessment-report.md#8-constraints-and-limitations-and-their-impact-irap-ar-0006). Each limitation is mapped to the controls it affects |
| **0007** | Gathers consumer recommendations from the provider, evaluates and includes them | **Conforms** | [01 §9](01-security-assessment-report.md#9-consumer-recommendations-from-the-provider-irap-ar-0007) — the entity's tenant-directed guidance is extracted and evaluated, with two caveats for consuming entities |
| **0023** | Assesses only what is implemented, not what will be implemented; may outline programs of work | **Partially conforms** | Programs of work are separated in [08](08-recommendations.md#programs-of-work-underway-irap-ar-0023) and not credited as controls. **Shortfall:** directed assumption A1 treats an undeployed estate as deployed, which is a departure declared at [00 §5.1](00-assessment-plan.md#51-directed-assumptions--and-their-conflict-with-irap-ar-0040) |
| **0032** | Key vulnerabilities the consumer or entity should be aware of are articulated as early as possible | **Conforms** | The two most consequential weaknesses appear in the executive summary at [01 §1.3](01-security-assessment-report.md#13-key-weaknesses-the-entity-should-be-aware-of-irap-ar-0032), before any other content |
| **0033** | Provides recommendations without designing or dictating how they are addressed | **Conforms** | [08](08-recommendations.md) states intent to be met and offers insight for consideration; no prescribed solutions. Explained at the head of that document |
| **0034** | Articulates potential impact but does not rate risks on behalf of the entity | **Conforms** | Findings carry **Potential impact** statements only. Severity ratings (Critical/High/Moderate/Low), used in an earlier draft, were removed. [03](03-findings-register.md) explains this at the head |
| **0044** | Clearly outlines the shared responsibility model | **Conforms** | [01 §4](01-security-assessment-report.md#4-shared-responsibility-model-irap-ar-0044) — a three-layer responsibility table with findings mapped to each contested boundary |
| **0045** | Report and matrix reviewed by security professionals internally and by the stakeholder before release | **Cannot conform** | No review occurred. Single-pass authorship by a non-independent, non-registered author. Declared at [01 §11](01-security-assessment-report.md#11-report-review-irap-ar-0045) |
| **0046** | Provides a complete report and control matrix articulating strengths, weaknesses, findings and recommendations | **Conforms** | Both minimum deliverables present — [01](01-security-assessment-report.md) (report) and [02](02-cloud-controls-matrix.md) (matrix). Strengths at [01 §5](01-security-assessment-report.md#5-security-strengths) and [03 Positive findings](03-findings-register.md#positive-findings-irap-ar-0045) |

## Quality standard 2 — Assessment process and frameworks

| Req | Requirement | Status | Where / why |
|-----|-------------|--------|-------------|
| **0012** | Utilises necessary Australian Government frameworks, policies and guidance, including ISM and PSPF | **Partially conforms** | ISM June 2026 applied throughout. **Shortfall:** the PSPF was not applied. For a system holding Australian Government data, PSPF governance, information and personnel security requirements would form part of a real assessment |
| **0013** | Uses the latest ISM release available prior to commencement | **Conforms** | June 2026 (`2026.06`) confirmed as the current release at assessment date, matching the entity's pinned release |
| **0014** | Where assessment lapses 2 ISM releases, a delta assessment against the current version is conducted | **Not applicable** | Assessment conducted within a single release cycle |
| **0015** | Report outlines risk management processes the entity uses to manage risks and threats | **Conforms** | [01 §7](01-security-assessment-report.md#7-risk-management-processes-used-by-the-entity-irap-ar-0015) — describes the entity's SRMP process, acceptance authority and exception register, without endorsing its ratings |
| **0022** | Follows the methodologies and approaches in the CAF, building on them where necessary | **Conforms** | Four stages, three methods, evidence quality scale, assessment degree and layering model all applied. Extension: a third layer for non-AWS dependencies, explained at [00 §1.3](00-assessment-plan.md#13-layering-per-caf-layering-irap-assessments) |
| **0039** | Report clearly articulates activities conducted during each stage | **Conforms** | [00 §2.1](00-assessment-plan.md#21-assessment-stages-irap-ar-0012) — a stage-by-stage table stating what was and was not performed, including that Stage 1 (ASD notification, COI declaration) did not occur |

## Quality standard 3 — Evidence gathering

| Req | Requirement | Status | Where / why |
|-----|-------------|--------|-------------|
| **0001** | Assesses all components within the boundary, using sampling only where appropriate | **Partially conforms** | All *architectural* components within the boundary were examined. **Shortfall:** control coverage was sampled at 47 of ~1,101, which is broader sampling than "only where appropriate" contemplates |
| **0002** | Clearly explains the sampling methodology, its advantages, disadvantages and why chosen | **Conforms** | [00 §2.5](00-assessment-plan.md#25-sampling-methodology-irap-ar-0002) — judgemental sampling declared, with selection criteria, stated non-representativeness, selection bias acknowledged, and the ~1,054 unassessed controls recorded |
| **0005** | Where sufficient evidence cannot be obtained, limitations and impact documented and controls marked accordingly | **Conforms** | [07 §3](07-evidence-register.md#3-evidence-sought-and-not-obtained-irap-ar-0005) tabulates evidence sought, why needed, impact and affected controls. 15 controls marked **No visibility** accordingly |
| **0026** | Gathers evidence of sufficient quality, appropriate to the system and control | **Partially conforms** | Evidence quality is assessed and declared against the CAF's four-level scale. **Shortfall:** the ceiling reached was **Fair**; no Good or Excellent evidence was obtainable, which is disclosed rather than remedied |
| **0027** | Outlines, in report and matrix, the evidence gathered supporting implementation and ongoing maintenance | **Conforms** | [07](07-evidence-register.md) lists every object by type and quality; [02](02-cloud-controls-matrix.md) names assessment objects per control |

## Quality standard 4 — Coverage

| Req | Requirement | Status | Where / why |
|-----|-------------|--------|-------------|
| **0017** | Regularly reviews, validates and maintains the assessment boundary | **Partially conforms** | Boundary defined and validated against the entity's SSP. **Shortfall:** a single-pass exercise provides no opportunity for the iterative review this contemplates |
| **0018** | Report clearly defines the assessment boundary | **Conforms** | [00 §1.1](00-assessment-plan.md#11-the-assessment-boundary-irap-ar-0018) and [01 §2](01-security-assessment-report.md#2-assessment-boundary-irap-ar-0018), including environments in scope |
| **0019** | Covers data sovereignty, offshore equipment and staff, or any information (including metadata) not within Australia | **Conforms** | [04 §2.4](04-layer-1-aws.md#24-data-residency--effective-with-one-observation) and matrix ISM-1395. Offshore exposure identified: EXC-001 `us-east-1` CloudFront/ACM management, and OBS-01 raising edge TLS termination outside Australia — a point the entity's own residency analysis does not address |
| **0020** | Where multiple services are covered, each is assessed against applicable controls, with deviations from common controls outlined per service | **Conforms** | Per-layer assessments in [04](04-layer-1-aws.md), [05](05-layer-2-kestrel.md), [06](06-layer-3-third-parties.md); deviations from the entity's own matrix tabulated at [02](02-cloud-controls-matrix.md#deviations-from-the-entitys-own-control-matrix-irap-ar-0020) |
| **0021** | Rationale for controls, systems and architecture out of scope is clearly articulated | **Conforms** | [00 §1.2](00-assessment-plan.md#12-out-of-scope-with-rationale-irap-ar-0021) — each exclusion carries a rationale; [01 §2](01-security-assessment-report.md#2-assessment-boundary-irap-ar-0018) repeats it for the report audience |
| **0029** | Understands the previous IRAP assessment report and outlines relevant findings | **Conforms** | [00 §4](00-assessment-plan.md#4-prior-assessments-irap-ar-0019). No prior IRAP assessment exists; the entity's internal self-assessment was examined, FIND-012's remediation verified in configuration, FIND-019 carried forward |
| **0031** | Assessment covers all applicable environments, software, workstations, network devices, servers and other devices or services within the boundary | **Partially conforms** | All in-boundary AWS services and network components examined. **Shortfall:** no workstation or endpoint is in boundary (OBS-05 notes the dependency), and no device was examined in operation |

## Quality standard 5 — Objectivity

| Req | Requirement | Status | Where / why |
|-----|-------------|--------|-------------|
| **0004** | Bases the assessment on presented evidence and facts; makes no inappropriate assumptions | **Cannot conform** | Directed assumptions A1 (estate deployed, evidence objects exist) and A2 (workflows enabled) are precisely the assumptions this prohibits. Declared prominently at [00 §5.1](00-assessment-plan.md#51-directed-assumptions--and-their-conflict-with-irap-ar-0040) and repeated in [01](01-security-assessment-report.md) and [README](README.md) |
| **0040** | Report and matrix clearly articulate why a control, design, process or procedure is effective or ineffective | **Conforms** | Every outcome in [02](02-cloud-controls-matrix.md) carries a justification naming the objects examined and the reasoning, including for Not applicable and Not implemented |
| **0041** | Does not use statements of compliance, conformity, certification or authorisation | **Conforms** | No such statement appears. An earlier draft's "authorise with conditions" recommendation was removed. Declared at [00 §7](00-assessment-plan.md#7-statements-this-pack-does-not-make-irap-ar-0041) and [01 §1.5](01-security-assessment-report.md#15-this-report-makes-no-compliance-or-authorisation-statement-irap-ar-0041) |
| **0042** | Report does not include biased or misleading statements or marketing jargon | **Partially conforms** | No marketing language; findings raised against the author's own prior work. **Shortfall:** authorship bias cannot be self-certified away — see 0008–0011 below |

## Quality standard 6 — Technical accuracy and completeness

| Req | Requirement | Status | Where / why |
|-----|-------------|--------|-------------|
| **0016** | Where the assessor lacks sound technical understanding, they are supported by a team with the relevant expertise | **Cannot conform** | No assessment team exists. Single author, no specialist support, no peer verification of technical conclusions |
| **0024** | Outlines the assessment objects and methods utilised in the control matrix for each control | **Conforms** | [02](02-cloud-controls-matrix.md) names objects and method per control. Method is **Examine** throughout, with Interview and Test declared unavailable |
| **0025** | Report outlines the vulnerabilities and weaknesses of the system | **Conforms** | [03](03-findings-register.md) — 20 findings and 5 observations; summarised at [01 §6](01-security-assessment-report.md#6-security-weaknesses-irap-ar-0025) |
| **0028** | Where technology capabilities and services are used, their function and purpose is outlined | **Conforms** | [01 §3.2](01-security-assessment-report.md#32-technologies-and-their-function-irap-ar-0028) — a table explaining each technology's function in this system, including the SCP/RCP distinction |
| **0030** | Where the entity uses technical guidance, deviations from that guidance are detailed | **Conforms** | [01 §3.4](01-security-assessment-report.md#34-deviations-from-technical-guidance-irap-ar-0030) — deviation from ASD Blueprint patterns and from AWS Control Tower/LZA, with the entity's documented reasoning |
| **0035** | Demonstrates sound technical understanding of the system and testing controls, articulated through the report | **Partially conforms** | Technical analysis is specific and traceable to named resources. **Shortfall:** no control was tested, so understanding of *testing* controls is not demonstrated |
| **0036** | Report is written in a manner appropriate for the intended audience | **Conforms** | [01](01-security-assessment-report.md) written for authorising officers, system owners and risk owners; [02](02-cloud-controls-matrix.md) for technical personnel and administrators, per the CAF's stated audiences |
| **0037** | Explains and details technical aspects clearly, providing detail and high-level descriptions | **Conforms** | [01 §3](01-security-assessment-report.md#3-system-overview-irap-ar-0037-irap-ar-0038) provides both; layer reports provide depth |
| **0038** | Clearly explains system architecture, design and the implementation of security controls | **Conforms** | [01 §3](01-security-assessment-report.md#3-system-overview-irap-ar-0037-irap-ar-0038) with OU tree, data flows and control implementation; expanded in [05](05-layer-2-kestrel.md) |
| **0043** | Alternate controls effectively meet the intent of the ISM control, supported by sufficient evidence | **Conforms** | One control rated **Alternate control** (ISM-1428, data perimeter meeting egress-control intent by organisational boundary rather than conventional DLP), with its evidence and coverage gaps recorded |

## Quality standard 7 — Assessment integrity

| Req | Requirement | Status | Where / why |
|-----|-------------|--------|-------------|
| **0008** | Submits a Conflict of Interest declaration to ASD IRAP before commencing | **Cannot conform** | No declaration submitted; no IRAP engagement exists. The author is not registered with ASD IRAP |
| **0009** | COI declaration submitted at least 7 business days before commencement | **Cannot conform** | As above |
| **0010** | Maintains and updates the COI declaration throughout, informing ASD IRAP of changes | **Cannot conform** | As above |
| **0011** | Report outlines all conflicts of interest for authorising officers | **Conforms (in intent)** | [00 §6](00-assessment-plan.md#6-conflict-of-interest-irap-ar-0008-0009-0010-0011) declares a **material and disqualifying** conflict: the author produced the documentation being assessed, in the same session. A registered assessor in this position would be required to decline the engagement |

---

## The requirements this pack cannot satisfy

Nine requirements cannot be met, and they are not peripheral:

| Req | What it requires | Why it cannot be met here |
|-----|------------------|---------------------------|
| 0004 | No inappropriate assumptions | Directed assumptions A1 and A2 are exactly that |
| 0008, 0009, 0010 | COI declaration to ASD IRAP | No registration, no engagement |
| 0016 | Technical support from an assessment team | Single author, no team |
| 0045 | Independent review before release | Single-pass, no review |

Plus three that could only be partially met — PSPF coverage (0012), evidence quality ceiling
(0026), and control testing (0035).

**Taken together, these define the gap between this exercise and an IRAP assessment.** The
pack can adopt the framework's structure, terminology, and discipline. It cannot supply
registration, independence, a team, testing, or the evidence access a real engagement
commands.

That gap is the reason for the disclaimer on every document in this folder, and the reason
this pack's value is as a rehearsal — it surfaces the questions a registered assessor would
ask, so the entity can answer them before being asked.
