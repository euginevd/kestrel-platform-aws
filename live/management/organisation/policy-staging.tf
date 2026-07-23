# Guardrails step 1 — the proving ground, added to the tree by the
# Guardrails PR (the two OUs Accounts deliberately left absent).
#
# Preventative policies have no dry-run mode; a wrong deny is a
# production outage. Every candidate attaches to Policy-Staging first and
# promotes to Workloads only by PR.

resource "aws_organizations_organizational_unit" "policy_staging" {
  name      = "Policy-Staging"
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = local.standard_tags
}

# Exceptions holds what a uniform Prod policy cannot (a Sydney-only-pinned
# workload, CloudFront's us-east-1 certificates) — with owner, expiry and
# a compensating control per account (policy/../exceptions.yaml), or it
# becomes where non-compliant things go to stay.
resource "aws_organizations_organizational_unit" "exceptions" {
  name      = "Exceptions"
  parent_id = aws_organizations_organizational_unit.top["Workloads"].id

  tags = local.standard_tags
}

resource "aws_organizations_account" "canary" {
  name      = "kestrel-policy-canary"
  email     = "root+policy-canary@aws.kestrel.com.au"
  parent_id = aws_organizations_organizational_unit.policy_staging.id

  # A canary with nothing in it passes everything — it is furnished with a
  # VPC, a deployment-shaped role, a bucket, a KMS key and a secret so
  # each policy has something to break (Guardrails step 2; the furniture
  # lives in the canary's own workload repo, per the boundary Bootstrap
  # decision 4 drew).

  tags = local.standard_tags

  lifecycle {
    prevent_destroy = true
  }
}
