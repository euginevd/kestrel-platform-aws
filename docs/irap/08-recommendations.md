# 08 — Recommendations

> **NOT AN IRAP ASSESSMENT.** The author is not an ASD-endorsed IRAP assessor. See
> [README](README.md).

## How these recommendations are written (IRAP-AR-0033)

Per IRAP-AR-0033, an IRAP assessor **must not design or dictate the manner in which a
recommendation is addressed**. Recommendations describe the issue, explain its implications,
and offer insight the entity can weigh using its own risk-based approach.

Accordingly, each recommendation below states **the intent to be met**, not a solution to be
implemented. Where an approach is mentioned, it is offered as one option among others the
entity may prefer.

**These recommendations are not conditions of authorisation.** Per IRAP-AR-0041, this pack
makes no authorisation statement. The authorising officer determines what, if anything, must
be addressed before the system is authorised, and on what timeframe.

**Ordering** reflects the assessor's view of consequence, not a risk rating — risk rating is
the entity's responsibility (IRAP-AR-0034).

---

## Group A — Matters the assessor suggests considering first

### A1. Establish whether brownfield accounts hold PROTECTED data

**Related finding:** [FIND-K07](03-findings-register.md#find-k07)

**Intent to be met.** The entity should be able to state, and an authorising officer should
be able to see, whether any account operating outside the zone control layer stores,
processes or communicates PROTECTED data.

**Why this matters.** Approximately 60 accounts — the numerical majority of the estate — do
not carry the network containment the SSP describes. Whether that is a significant exposure
or an acceptable transitional state depends entirely on what those accounts hold, and no
examined object answers that question. Until it is answered, the exposure cannot be sized by
the entity or by anyone relying on the entity's documentation.

**Insight for consideration.** The entity already operates an organisation-wide resource
index (Resource Explorer) and data classification tooling (Macie), both of which appear
capable of contributing to this determination without new investment. The entity may also
wish to consider whether graduation sequencing should be driven by exposure — accounts
holding sensitive data, or with internet-reachable resources — rather than by convenience or
alphabetical order.

**Observation on timeframe.** The entity's own accepted expiry is 2027-06-30 for the full
population. The determination of *what those accounts hold* is a smaller undertaking than
graduating them, and may warrant a shorter timeframe than the graduation itself.

---

### A2. Meet the intent of least privilege for `WorkloadDeploy`, or register the deferral

**Related finding:** [FIND-K03](03-findings-register.md#find-k03)

**Intent to be met.** Privileged access limited to what each role requires. Where a broader
grant is temporarily accepted, its expiry is detectable rather than dependent on recall.

**Why this matters.** `PowerUserAccess` is a very broad standing grant for a named group at
PROTECTED. The entity has already identified this and defined a replacement condition; the
weakness is that nothing detects the condition being met.

**Insight for consideration.** The entity has built a mechanism that solves exactly this
class of problem — the exception register reconciles at plan time and fails when an
exception outlives its expiry. This deferral is not currently on that register. Placing it
there would make the entity's existing intent self-enforcing.

The entity may separately wish to consider whether "Non-Prod holds no production data" should
remain a policy position or become an enforced control, given it is currently the principal
compensating argument for the grant's breadth.

---

### A3. Align absolute claims in documentation with configuration

**Related findings:** [FIND-T03](03-findings-register.md#find-t03),
[FIND-K01](03-findings-register.md#find-k01), [FIND-K05](03-findings-register.md#find-k05)

**Intent to be met.** A reader of the System Security Plan should not be able to form a
broader impression of a control's coverage than the configuration provides.

**Why this matters.** The SSP states there are no long-lived credentials anywhere in the
estate, while the exception register records a long-lived GitHub token scoped to
`admin:org`. The statement is literally accurate — this is not an AWS IAM key — but an
assessor who encounters the exception after reading the claim will reasonably re-examine
every other absolute statement in the document. The cost is to the documentation's
credibility, which is disproportionate to the credential's actual significance.

**Insight for consideration.** Three specific places where precision would strengthen the
document: the credential claim in §17; the chapter deferrals that name an owner but not the
system where the control is assessed; and the description of `deny-root`, where the
management-account exclusion is stated elsewhere but not where a reader would look for it.

The assessor notes this recommendation is about **precision, not weakness**. The underlying
controls are sound; the documentation currently overstates two of them slightly, which in an
assessment context costs more than it gains.

---

## Group B — Assurance over dependencies

### B1. Obtain assurance for third parties holding credential custody and deployment authority

**Related findings:** [FIND-T06](03-findings-register.md#find-t06),
[FIND-T04](03-findings-register.md#find-t04)

**Intent to be met.** Suppliers whose compromise would materially affect the system carry
assurance proportionate to their role, as GOV-11 now requires with independent verification.

**Why this matters.** CyberArk holds the credential that can override every control in the
estate, and appears in no supplier table and no risk. GitHub is the control plane —
determining what applies to production — and is excluded from supplier assurance on a
rationale that reasons from data classification rather than from role.

**Insight for consideration.** The entity's existing supplier reasoning is sound for AWS and
Microsoft. Applying the same reasoning from *role* rather than from *data held* would likely
bring both of these into scope naturally. For CyberArk specifically, the entity may wish to
establish whether the two-person rule is enforceable within the vault or rests entirely on
procedure, since ADR-0002's control narrative depends on the answer.

---

### B2. Make the elevation approval workflow evidenceable

**Related finding:** [FIND-T01](03-findings-register.md#find-t01)

**Intent to be met.** The control governing how privilege is obtained across the estate can
be examined, not merely asserted.

**Why this matters.** The AWS-side configuration proves elevation groups hold no standing
grant. It cannot prove who approves an activation, whether self-approval is possible, or
what activation duration is permitted — all of which reside in Entra PIM. The entity claims
this control as met; the evidence supports only half of it.

**Insight for consideration.** The entity's own principle — that controls should emit
evidence by running — applies here and is currently applied only within AWS. A periodic
configuration export from PIM would extend that principle across the seam. The entity may
also wish to consider whether PIM configuration changes should travel a review path
comparable to the one Terraform changes travel.

---

### B3. Reconcile the SOC's monitoring scope with its documented role

**Related finding:** [FIND-T05](03-findings-register.md#find-t05)

**Intent to be met.** Both parties agree, in writing, what the provider receives, what it
monitors, and what it is accountable for detecting (ISM-1569).

**Why this matters.** The Security Lake subscriber grants one source. The documentation
describes 24×7 triage, and incident playbooks assume visibility of network and data-access
activity. One of these is inaccurate. A detection responsibility that each party believes the
other holds is a common and consequential failure in outsourced monitoring.

**Insight for consideration.** The entity already made a strong decision in defining the SLA
at the Event Hub handoff point. Extending that clarity to *which sources cross the seam*
would complete it.

---

### B4. Pin the AWS inheritance reference and confirm scope by Region

**Related findings:** [FIND-A01](03-findings-register.md#find-a01),
[FIND-A02](03-findings-register.md#find-a02)

**Intent to be met.** Inherited controls are traceable to a specific, current, scoped
assessment report, and are claimed only for services and Regions within that scope.

**Why this matters.** Inheritance is recorded as a bare string with no version, date or
scope. Separately, the architecture depends on services whose assessed status — particularly
in `ap-southeast-4` — is not confirmed anywhere. An inheritance gap in Melbourne would sit
precisely where the continuity posture expects to rely on it.

**Insight for consideration.** The entity already demonstrates the required discipline
elsewhere: the `region-deny` policy records its source list as vendored from AWS's
maintained list, with a date. The same treatment applied to the assessment report reference,
and a review trigger in the Continuous Monitoring Plan alongside the existing ISM re-pinning
process, would close both findings together.

---

## Group C — Control coverage

### C1. Make data-event logging scope determinable

**Related finding:** [FIND-K02](03-findings-register.md#find-k02)

**Intent to be met.** Where object-level access logging is scoped, the scoping mechanism is
enforced, so coverage can be determined rather than assumed.

**Why this matters.** Data events are scoped by bucket-name prefix, and no examined object
requires PROTECTED data to reside in a bucket carrying that prefix. This bears directly on
the threat the entity names as primary — an insider reading data with valid credentials —
because object-level read visibility has no substitute among the stated compensating
controls.

**Insight for consideration.** The entity may wish to consider whether classification rather
than naming should drive logging scope, or alternatively whether the naming convention should
become an enforced control. The entity's own risk register (R-09) may warrant revisiting in
light of the assessor's differing view of the compensating controls.

---

### C2. Extend perimeter coverage to data-bearing services

**Related finding:** [FIND-K09](03-findings-register.md#find-k09)

**Intent to be met.** A perimeter intended to prevent unauthorised data movement addresses
the paths through which data can move, or records why particular paths are excluded.

**Why this matters.** The perimeter policies enumerate four services. Cross-account data
paths through CloudWatch Logs subscriptions, SNS, SSM Parameter Store, ECR and others are
not constrained. The absence of `logs` is the most consequential; the absence of `sns`
alongside `sqs` appears unintentional.

**Insight for consideration.** The entity describes the perimeter as closed in three
directions. Recording either the extended coverage or the rationale for each exclusion would
make the perimeter's actual extent something an assessor can reason about.

---

### C3. Narrow egress destinations

**Related finding:** [FIND-K06](03-findings-register.md#find-k06)

**Intent to be met.** Egress filtering constrains destinations to those required.

**Why this matters.** `.amazonaws.com` permits egress to every AWS endpoint globally,
including third-party S3 buckets; `.github.com` permits egress to arbitrary repositories. For
a system whose primary threat is exfiltration, the egress control provides less containment
than its presence implies.

**Insight for consideration.** VPC endpoints with endpoint policies can enforce
organisation-scoped conditions that domain-based filtering cannot. The entity may also note
that its own delivery model vendors modules rather than fetching at apply time, which may
mean the GitHub allowance is broader than runtime requires.

---

### C4. Apply silence-detection reasoning to the alerting path itself

**Related finding:** [FIND-K10](03-findings-register.md#find-k10)

**Intent to be met.** The failure of the notification path is itself detected.

**Why this matters.** Every alarm in the design — including evidence-tamper and
source-silence — routes to a single SNS topic with no examined subscription, escalation or
delivery-failure monitoring. The entity's own reasoning for monitoring log-source silence
applies identically one level up.

**Insight for consideration.** This is the entity's own design principle, not the assessor's,
applied to the one component it currently exempts.

---

### C5. Automate the root ceremony reconciliation

**Related finding:** [FIND-K04](03-findings-register.md#find-k04)

**Intent to be met.** Where a control cannot be technically enforced, its verification occurs
close to the event rather than during a later investigation.

**Why this matters.** The two-person rule depends on correlating vault checkout records with
CloudTrail. The incident response plan describes this correlation as an investigation step —
performed after the event that mattered.

**Insight for consideration.** Root use already pages at any severity. The entity may wish to
consider whether a checkout record with no matching root event, or a root event with no
matching checkout, should raise the same page.

---

### C6. Assign tenant data backup responsibility

**Related finding:** [FIND-K11](03-findings-register.md#find-k11)

**Intent to be met.** Backup and restoration responsibility is assigned, and restoration is
tested.

**Why this matters.** The archive covers logs; ADR-0005 covers service continuity. Neither
covers tenant data, and the shared responsibility model does not assign it. A responsibility
absent from that model may be assumed by neither party.

---

### C7. Extend replica protections to match the primary

**Related finding:** [FIND-K08](03-findings-register.md#find-k08)

**Intent to be met.** Protective properties applied to a primary evidence store apply to its
copies.

**Insight for consideration.** The entity's own FIND-012 established that
"two-clocks-must-not-disagree care applies to every copy." That reasoning was applied to
lifecycle configuration; the assessor suggests considering whether it applies equally to key
policy.

---

### C8. Verify tenant security documentation exists

**Related finding:** [FIND-T07](03-findings-register.md#find-t07)

**Intent to be met.** Where controls are deferred to another party, the existence of that
party's security documentation is verifiable.

**Insight for consideration.** The account factory already vends from a declared map entry.
The entity may wish to consider whether that entry is the natural place to record the tenant
SSP reference, making the deferral chain traceable at the point the account is created.

---

### C9. Model identity provider compromise discretely

**Related finding:** [FIND-T02](03-findings-register.md#find-t02)

**Intent to be met.** Scenarios whose consequence differs materially from their peer group
are modelled discretely, with proportionate response guidance.

**Why this matters.** Entra ID compromise is estate-wide compromise, currently addressed
within a general supplier risk alongside GitHub and the SOC. The incident response plan has
playbooks for root and pipeline compromise but none for the identity provider.

**Insight for consideration.** The entity has already solved the hardest part of this
problem: break-glass sits deliberately outside Entra so an IdP failure cannot lock out the
estate that would fix it. A playbook would connect that existing design decision to the
scenario it was built for.

---

## Programs of work underway (IRAP-AR-0023)

The framework permits an assessor to note programs of work underway, while assessing only
what is implemented. The entity has the following in progress, none of which was assessed as
implemented:

| Work | Entity's stated timeframe |
|------|---------------------------|
| Brownfield account graduation | Expiry 2027-06-30 |
| Application control deployment (FIND-019) | Expiry 2026-12-01 |
| `WorkloadDeploy` scoped policy replacement | On first agency-facing Prod workload |
| CloudFront `us-east-1` exception (EXC-001) | Expiry 2027-06-30 |
| GitHub SCIM token exception (EXC-002) | Expiry 2027-07-01 |

Per IRAP-AR-0023, these are recorded as intentions rather than assessed as controls.
