# Accounts step 4 — delegate administration OUT of the management account.
#
# The second registration main.tf flags: trusted access reaches a service;
# this names WHICH ACCOUNT administers it. Five detective services to
# security-tooling, sso to identity — separate, because granting access
# and watching access are different jobs, and one admin who can do both
# can widen access AND administer the detection that would notice.
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
  ])

  account_id        = aws_organizations_account.core["security-tooling"].id
  service_principal = "${each.key}.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "identity" {
  account_id        = aws_organizations_account.core["identity"].id
  service_principal = "sso.amazonaws.com"
}

# account.amazonaws.com is deliberately delegated to NO ONE — alternate
# contacts change through this leaf or not at all.
