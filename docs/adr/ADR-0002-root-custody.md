# ADR-0002 — Root credential custody

Status: Accepted · Date: 2026-07-19 · Part: Organisation (decision 1)

## Context

The management account's root credential can undo any control above it,
and no guardrail above the management account can protect it. It
outlives every later control.

## Decision

Root credentials live in **CyberArk** — check-out, approval, session
logging — generated directly into the safe so the password exists in
exactly one place. Root MFA is **two YubiKey 5 FIPS keys**: primary in
the Sydney HQ safe, backup in Melbourne, **both registered at setup**,
because you can't do the backup calmly mid-incident. Zero access keys —
a key bypasses the MFA.

Custody runs a **two-person rule**: operator plus witness for any root
ceremony, with the checkout log and CloudTrail pair as evidence.
Break-glass stays root-plus-YubiKey, deliberately **outside Entra ID**,
so an IdP outage can't lock the estate that would fix it. Drill cadence
is quarterly, timed and witnessed against a locked scenario (executed in
Identity, step 12).

## Consequences

Root is a ceremony, not a login — slower by design. Two cities hold
hardware; losing both safes simultaneously is the accepted residual.
"Who can act as root, and when did they last?" has a checkout log, a
witness and a drill result.
