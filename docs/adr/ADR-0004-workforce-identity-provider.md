# ADR-0004 — Entra ID as the workforce identity provider

Status: Accepted · Date: 2026-07-19 · Part: Organisation (decision 2)

## Context

IAM Identity Center federates from one directory; every human's access
to the estate traces back to it. Two candidates: Entra ID (already
licensed and run — Kestrel's M365 directory, joiner-mover-leaver wired
to HR, conditional access live) and Okta (the strongest independent IdP,
but a new platform to buy, run, assess and migrate every identity onto).

## Decision

**Entra ID.** Its already being in use is the whole argument: a second
IdP means paying to re-solve a solved problem while doubling the
identity attack surface and the assessment scope. The phishing-resistant
MFA bar needs Entra ID P2 conditional access either way — the AWS app's
conditional access policy scopes the `Require authentication strength`
grant with the built-in Phishing-resistant MFA strength (FIDO2/passkeys),
not the generic "require MFA" that SMS or push satisfies.

## Consequences

Deeper Microsoft coupling — accepted, since M365 makes that coupling a
fact regardless. Flips: never, while identity lives in Microsoft's
stack. The Entra tenant itself (conditional access, tenant hardening) is
its own piece of work, named rather than assumed (Identity's outcome).
