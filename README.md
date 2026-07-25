# kestrel-platform-aws

The platform repository for **Kestrel Digital's AWS landing zone** — the reference
implementation behind the ArcVault series
[AWS Landing Zone](https://arcvault.com.au/in-practice/aws-landing-zone/).

[Kestrel Digital](https://arcvault.com.au/in-practice/) is a **fictional scenario**: a
Sydney SaaS scale-up hosting Australian Government data up to PROTECTED, assessed under
IRAP against the ISM. This repo is the code the series' pages abridge — every decision,
layout choice and snippet on the pages resolves to a real file here.

> **This is a reference implementation, not a deployable estate.** Every identifier is a
> placeholder — org ID `o-kestrel00id`, account IDs like `123456789012`, emails on
> `kestrel.com.au` / `aws.kestrel.com.au`. Nothing points at real infrastructure, and no
> secret of any kind exists in this history. **Nothing here has been IRAP assessed** —
> the series' final part is a self-assessment on IRAP methodology, which is not an IRAP
> assessment; that requires a registered assessor.

## 🎯 What it is

A landing zone is the **multi-account foundation everything else deploys into** — a new
workload inherits identity, guardrails, logging and networking on day one instead of
bolting them on later. The estate grew one project at a time to **~60 accounts**, each
with its own idea of "secure", and is heading past 150 as every dedicated tenant gets its
own accounts. This repo rebuilds it as an organisation **governed entirely as code**:

- **Secure by default** — guardrails inherited on day one, not a later hardening pass.
- **Sovereign by default** — Australian Regions only (`ap-southeast-2`, `ap-southeast-4`),
  provable from configuration.
- **Entirely as code** — the organisation changes only through a reviewed pull request.
- **Assessor-ready continuously** — every control emits evidence by running, mapped to the ISM.

## 🗺️ The estate, grouped by policy

An [SRA](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/)-aligned
OU tree — grouped by policy, not org chart. The
[full tree with every account](https://arcvault.com.au/in-practice/aws-landing-zone/accounts/)
lives in the **Accounts** page; the top level is:

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

## 📚 The series, part by part

Each part settles decisions the next ones cite. The page is the canonical narrative; the
repo path is where its Terraform, ADRs and policy live.

| Part | Page | What it lands | Where it lands in this repo |
|------|------|---------------|-----------------------------|
| 1 | [Organisation](https://arcvault.com.au/in-practice/aws-landing-zone/organisation/) | Management account hardened in one witnessed session — root under PAM, federation to Entra ID. | No code — a console session. Decisions are [`docs/adr/`](docs/adr/) ADR-0001 onwards. |
| 2 | [Bootstrap](https://arcvault.com.au/in-practice/aws-landing-zone/bootstrap/) | The delivery path — repo with review/policy gates, in-boundary S3 state, OIDC pipelines. | [`bootstrap/`](bootstrap/), [`.github/`](.github/), [`policy/`](policy/), [`accounts.json`](accounts.json) |
| 3 | [Accounts & Security Foundation](https://arcvault.com.au/in-practice/aws-landing-zone/accounts/) | SRA-shaped OU tree, the four remaining core accounts, every org-wide service delegated and enabled once, then ~60 brownfield accounts enrolled. | [`live/management/organisation/`](live/management/organisation/), [`live/log-archive/`](live/log-archive/), [`live/security-tooling/`](live/security-tooling/) |
| 4 | [Logging & Monitoring](https://arcvault.com.au/in-practice/aws-landing-zone/monitoring/) | Every log the estate emits into the Object-Locked archive — data events, two-speed Config, four watchers, then the OCSF seam to the SOC's Sentinel. | [`live/log-archive/`](live/log-archive/), [`live/security-tooling/`](live/security-tooling/), [`modules/account-baseline/`](modules/account-baseline/) |
| 5 | [Networking](https://arcvault.com.au/in-practice/aws-landing-zone/networking/) | Cloud WAN with a segment per zone, IPAM behind every CIDR, one logged egress per Region. | [`live/network/`](live/network/), [`modules/inspection-vpc/`](modules/inspection-vpc/), [`modules/firewall-rules/`](modules/firewall-rules/) |
| 6 | [Guardrails](https://arcvault.com.au/in-practice/aws-landing-zone/guardrails/) | Four policy instruments, member root deleted, the data perimeter closed in three directions. | [`live/management/policies/`](live/management/policies/) |
| 7 | [Identity](https://arcvault.com.au/in-practice/aws-landing-zone/identity/) | Standing privilege removed — JIT elevation via Entra PIM, last long-lived credentials deleted. | [`live/identity/`](live/identity/) |
| 8 | [Vending](https://arcvault.com.au/in-practice/aws-landing-zone/vending/) | The account factory — one PR vends an account born governed; decommissioning as deliberate. | [`live/management/accounts/`](live/management/accounts/), [`modules/account-factory/`](modules/account-factory/), [`modules/account-baseline/`](modules/account-baseline/) |
| 9 | [Assessment](https://arcvault.com.au/in-practice/aws-landing-zone/assessment/) | The estate assessed against itself — control-to-evidence matrix on a pinned ISM release. | [`docs/assessment/`](docs/assessment/) |

A [Reference](https://arcvault.com.au/in-practice/aws-landing-zone/reference/) page
collects every AWS service the parts touch, the alternative each decision rejected, and
every diagram in one place.

## 🧭 Key decisions

The load-bearing calls, each argued in full on its page and recorded as an ADR.

| Decision | Chose | Over | ADR |
|----------|-------|------|-----|
| Engine | Terraform-native on Organizations | Control Tower + LZA / AFT | [ADR-0003](docs/adr/ADR-0003-engine-and-state.md) |
| State | Self-managed S3, in-boundary | HCP Terraform (no AU region) | [ADR-0003](docs/adr/ADR-0003-engine-and-state.md) |
| Identity provider | Entra ID | Okta | [ADR-0004](docs/adr/ADR-0004-workforce-identity-provider.md) |
| Region posture | Both Regions active | Sydney primary, Melbourne pilot light | [ADR-0005](docs/adr/ADR-0005-region-posture.md) |
| Root custody | PAM + FIPS hardware MFA, credentials deleted | Deny root by SCP | [ADR-0001](docs/adr/ADR-0001-organisation-settings-and-email-scheme.md), [ADR-0002](docs/adr/ADR-0002-root-custody.md) |
| Network fabric | Cloud WAN | Transit Gateway | see [Networking](https://arcvault.com.au/in-practice/aws-landing-zone/networking/) |
| Account factory | Custom Terraform module | Account Factory for Terraform | see [Vending](https://arcvault.com.au/in-practice/aws-landing-zone/vending/) |

## 🗂️ Repo layout

```text
bootstrap/               # everything that must exist before the pipeline can
live/                    # thin root configs — one directory = one state object
├── management/
│   ├── organisation/    #   OU tree, delegation, brownfield enrolment
│   ├── policies/        #   SCPs, RCPs, declarative + tag policies
│   └── accounts/        #   the account-factory map
├── log-archive/         #   the immutable log sink + security lake (OCSF, the SOC seam)
├── security-tooling/    #   cloudtrail, config, detection, findings, pipeline alarms
├── network/             #   Cloud WAN core network, IPAM, egress, inspection
└── identity/            #   permission sets + Entra-group assignments
modules/                 # reusable, versioned, pinned by git tag
├── account-factory/     #   vend an account from a declared entry
├── account-baseline/    #   the birth baseline + brownfield graduation checklist
├── github-oidc/         #   split plan/apply OIDC roles
├── inspection-vpc/      #   per-Region egress + east-west inspection
└── firewall-rules/      #   Network Firewall rule groups
policy/                  # Checkov — security baseline + custom tag/naming checks
accounts.json            # leaf → account ID: how the pipeline routes
docs/                    # adr, assessment matrix, findings — docs-as-code
.github/                 # workflows (checks + plan/apply) + CODEOWNERS
```

Workload accounts never get directories here: they exist only as factory-map entries,
their infrastructure in their own repos.

## 📐 Conventions

- Every `live/<account>/<component>` leaf is one root config with its own state key —
  never one estate-wide state, so one bad apply can't take out the org.
- Every leaf pins the toolchain in an identical `versions.tf` and commits
  `.terraform.lock.hcl`; the pipeline verifies it with `terraform init -lockfile=readonly`.
- Modules are consumed only from `modules/`, pinned by git tag; the estate never pulls
  third-party code at apply time.
- Every resource is tagged `DataClassification`, `Owner`, `CostCentre` and `Application`.
- Workflows ship as `*.yml.disabled` and are enabled by `git mv` only once their
  prerequisites exist — an enabled workflow with nothing to run against fails on every push.

## 🧰 Tech stack

Terraform ≥ 1.10 · AWS Organizations · IAM Identity Center (federated from Entra ID) ·
Cloud WAN · Network Firewall · GuardDuty · Security Hub CSPM · Inspector · Macie ·
Security Lake (OCSF) · AWS Config · CloudTrail · S3 Object Lock · Athena · EventBridge ·
GitHub Actions with OIDC · Checkov.

## 🔒 Security

See [SECURITY.md](SECURITY.md). No credentials, keys or real account identifiers exist
anywhere in this history — every identifier is a documented placeholder.

## 📄 Licence

[Apache-2.0](LICENSE).
