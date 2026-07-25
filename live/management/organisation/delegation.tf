# Accounts step 4 — delegate administration OUT of the management account.
#
# The second registration main.tf flags: trusted access reaches a service;
# this names WHICH ACCOUNT administers it. Every org-wide security
# service to security-tooling, sso to identity — separate, because
# granting access and watching access are different jobs, and one admin
# who can do both can widen access AND administer the detection that
# would notice.
#
# Registration is all this leaf does: what each service records and
# where it goes is Logging & Monitoring (live/security-tooling/). fms is
# delegated here rather than to `network` — the account that owns the
# firewalls must not administer the thing that reverts hand-edits to
# them — and stays inert until Networking builds a fabric worth
# governing.
#
# Security Lake is the ONE exception to "security services go to
# security-tooling": the Lake IS retained log data, so it is delegated to
# log-archive and lands with the other immutable logs rather than with
# the tools that read them (Accounts decision 2).
#
# The Identity Center INSTANCE stays in the management account —
# delegation moves administration, not the instance, and a delegated
# admin cannot alter permission sets provisioned in the management
# account, so PlatformAdmin stays management-managed and `identity` can
# never grant access to the org root.

resource "aws_organizations_delegated_administrator" "security" {
  for_each = toset([
    "cloudtrail",
    "config",
    "guardduty",
    "securityhub",
    "access-analyzer",
    "inspector2",
    "macie",
    "resource-explorer-2",
    "fms",

    # Root-access management: the 15-minute task-scoped root sessions for
    # member accounts originate from security-tooling, not from the
    # management account and never from a standing credential.
    "iam",
  ])

  account_id        = aws_organizations_account.core["security-tooling"].id
  service_principal = "${each.key}.amazonaws.com"
}

# The Lake sits with the logs, not with the tools that read them.
resource "aws_organizations_delegated_administrator" "log_archive" {
  account_id        = aws_organizations_account.core["log-archive"].id
  service_principal = "securitylake.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "identity" {
  account_id        = aws_organizations_account.core["identity"].id
  service_principal = "sso.amazonaws.com"
}

# account.amazonaws.com is deliberately delegated to NO ONE — alternate
# contacts change through this leaf or not at all.
