# kestrel-platform-aws

The platform repository for **Kestrel Digital's AWS landing zone** — the reference
implementation behind the ArcVault series
[AWS Landing Zone](https://arcvault.com.au/in-practice/aws-landing-zone/).

Kestrel Digital is a **fictional scenario**: a Sydney SaaS company hosting Australian
Government data up to PROTECTED, assessed under IRAP against the ISM. This repo is the
code the series' pages abridge — every decision, layout choice and snippet on the pages
resolves to a real file here.

> **This is a reference implementation, not a deployable estate.** Every identifier is a
> placeholder — org ID `o-kestrel00id`, account IDs like `123456789012`, emails on
> `kestrel.com.au` / `aws.kestrel.com.au`. Nothing points at real infrastructure, and no
> secret of any kind exists in this history. **Nothing here has been IRAP assessed** —
> the series' final part is a self-assessment on IRAP methodology, which is not an IRAP
> assessment; that requires a registered assessor.

## The series, part by part

| Part | Page | Where it lands in this repo |
|------|------|-----------------------------|
| 1 | [Organisation](https://arcvault.com.au/in-practice/aws-landing-zone/organisation/) | No code — one witnessed console session. Its decisions are `docs/adr/` ADR-0001 onwards. |
| 2 | [Bootstrap](https://arcvault.com.au/in-practice/aws-landing-zone/bootstrap/) | `bootstrap/` (state backend, OIDC roles), `.github/` (workflows, CODEOWNERS), `policy/`, `accounts.json` |
| 3 | [Accounts & Security Foundation](https://arcvault.com.au/in-practice/aws-landing-zone/accounts/) | `live/management/organisation/`, `live/log-archive/`, `live/security-tooling/` |
| 4 | [Networking](https://arcvault.com.au/in-practice/aws-landing-zone/networking/) | `live/network/` |
| 5 | [Guardrails](https://arcvault.com.au/in-practice/aws-landing-zone/guardrails/) | `live/management/policies/`, `live/backup/` |
| 6 | [Identity](https://arcvault.com.au/in-practice/aws-landing-zone/identity/) | `live/identity/` |
| 7 | [Vending](https://arcvault.com.au/in-practice/aws-landing-zone/vending/) | `live/management/accounts/` |
| 8 | [Assessment](https://arcvault.com.au/in-practice/aws-landing-zone/assessment/) | `docs/assessment/` |

## Repo layout

```text
bootstrap/               # everything that must exist before the pipeline can
live/                    # thin root configs — one directory = one state object
├── management/          #   OU tree, factory map, permission sets
├── log-archive/         #   the immutable log sink
└── security-tooling/    #   cloudtrail, config, detection, access-analyzer
accounts.json            # leaf → account ID: how the pipeline routes
modules/                 # reusable, versioned, pinned by git tag
policy/                  # Checkov — security baseline + custom tag/naming checks
docs/                    # adr, registers, runbooks — docs-as-code
.github/                 # workflows (checks + plan/apply) + CODEOWNERS
```

The tree grows as the parts land — `live/network/`, `live/identity/`, `live/backup/` and
`live/management/accounts/` arrive with their parts. Workload accounts never get
directories here: they exist only as factory-map entries, their infrastructure in their
own repos.

## Conventions

- Every `live/<account>/<component>` leaf is one root config with its own state key —
  never one estate-wide state.
- Every leaf pins the toolchain in an identical `versions.tf` and commits
  `.terraform.lock.hcl`; the pipeline verifies it with `terraform init -lockfile=readonly`.
- Modules are consumed only from `modules/`, pinned by git tag; the estate never pulls
  third-party code at apply time.

## Licence

[Apache-2.0](LICENSE).
