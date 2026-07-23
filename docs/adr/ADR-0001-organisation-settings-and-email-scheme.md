# ADR-0001 — Organisation settings and the account email scheme

Status: Accepted · Date: 2026-07-19 · Part: Organisation (decision 1)

## Context

The organisation's founding settings are chosen once, before any console
work, because everything below inherits them and mistakes here are
expensive to unwind. Every account also needs a globally unique root
email that no individual owns.

## Decision

AWS Organizations in **all-features mode, one organisation only**.
Consolidated-billing-only can't do SCPs or delegated administration; a
separate production organisation buys isolation the OU boundary already
gives, at the price of duplicating every delegated service, guardrail
set and pipeline — structure without benefit at Kestrel's size.

**Centralised root access management and privileged root sessions on
from the start**, together: credentials management alone leaves a member
account that genuinely needs root with no way back, so task-scoped
sessions (15-minute ceiling) go on with it. Accounts created afterwards
are born without root credentials.

Account emails: a **dedicated subdomain for root, the corporate domain
for humans** — subaddressing onto a distribution list, the
AWS-documented way to give every account a unique root email without a
mailbox per account.

```text
root+<account-name>@aws.kestrel.com.au   →  per-account root, one restricted mailbox
aws-root-mgmt@kestrel.com.au             →  management account (outside the bulk scheme)
aws-billing@kestrel.com.au               →  monitored DL — billing alternate contact
aws-operations@kestrel.com.au            →  monitored DL — operations alternate contact
aws-security@kestrel.com.au              →  monitored DL — security alternate contact
```

Root emails are **never reusable** — an email used for an account can
never be used again, even after closure; the factory refuses retired
names.

## Consequences

All-features is changeable later only with every member account
accepting — trivial at one, a campaign at twenty, so it's settled now.
The two root-management capabilities create a dependency between their
halves, accepted for never having credentials to hunt down later. The
email scheme means account name and root email derive from one key and
cannot drift.
