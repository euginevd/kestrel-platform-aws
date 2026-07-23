# FIND-012

```text
Severity   : Moderate
Control    : ISM-0859
Expected   : event logs retained 7 years per NAA disposal authority, both Regions
Observed   : primary bucket sets 7-year expiry; Melbourne replica sets none
Disposition: PR #214 — replica lifecycle aligned to primary; re-test scheduled
```

The re-run walked the cross-Region replica in Melbourne and found the
retention there carried the twelve-month Glacier transition and no
expiry rule at all: retention provable in Sydney, unproven on the copy
an assessor would reach for if Sydney were the Region that was lost.

The severity is the assessor's call, not the author's comfort — a
retention the DR copy can't prove is Moderate whoever wrote the bucket,
and the format leaves no clause to say "but the primary is fine".

Disposition: **Fixed.** PR #214 added the missing
`expiration { days = 2555 }` to the Melbourne replica's lifecycle rule
(`live/log-archive/replica.tf`), the same two-clocks-must-not-disagree
care the primary got. The battery had no test asserting the *replica's*
retention — the fix PR added one, re-ran it green after the merge, and
the next assessment inherits the coverage.
