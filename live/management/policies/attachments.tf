# The policies and where they attach — OUs, never accounts, so an account
# vended tomorrow inherits enforcement before its first resource exists
# (Guardrails decision 4). Targeted denies on top of FullAWSAccess, never
# allow-lists.
#
# Promotion order is process, enforced by PR review: every candidate
# passed the canary battery in Policy-Staging, Non-Prod preceded Prod by
# a working day, and the root-attached policies took the three-PR path
# (Policy-Staging → Non-Prod → root), because a root attachment lands on
# Prod the instant it applies.

# --- Estate-wide layer: attached at the organisation root --------------------

resource "aws_organizations_policy" "deny_root" {
  name        = "deny-root"
  description = "Root as depth — the credential is deleted (Guardrails step 5); this covers newly invited accounts before the sweep runs."
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/deny-root.json")

  tags = local.standard_tags
}

resource "aws_organizations_policy_attachment" "deny_root" {
  policy_id = aws_organizations_policy.deny_root.id
  target_id = local.root_id
}

resource "aws_organizations_policy" "region_deny" {
  name        = "region-deny"
  description = "Australian Regions only. NotAction list vendored from AWS Control Tower's maintained Region-deny carve-out, read 2026-07-20 — never hand-written; an omission is an outage in a service nobody connected to Region."
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/region-deny.json")

  tags = local.standard_tags
}

resource "aws_organizations_policy_attachment" "region_deny" {
  policy_id = aws_organizations_policy.region_deny.id
  target_id = local.root_id
}

resource "aws_organizations_policy" "org_perimeter" {
  name        = "org-perimeter"
  description = "RCP: external principals refused by S3, KMS, STS, Secrets Manager and SQS even where a resource policy grants them access. Attached after the 90-day CloudTrail pass produced the exemption list."
  type        = "RESOURCE_CONTROL_POLICY"
  content     = file("${path.module}/org-perimeter.json")

  tags = local.standard_tags
}

resource "aws_organizations_policy_attachment" "org_perimeter" {
  policy_id = aws_organizations_policy.org_perimeter.id
  target_id = local.root_id
}

resource "aws_organizations_policy" "resource_perimeter" {
  name        = "resource-perimeter"
  description = "SCP: our principals cannot write to resources outside the org — closes exfiltration to an in-Region attacker bucket, the path every other control satisfies. Exemptions: resource-perimeter-exemptions.md."
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/resource-perimeter.json")

  tags = local.standard_tags
}

resource "aws_organizations_policy_attachment" "resource_perimeter" {
  policy_id = aws_organizations_policy.resource_perimeter.id
  target_id = local.root_id
}

resource "aws_organizations_policy" "protect_platform" {
  name        = "protect-platform"
  description = "The machinery producing every proof is not deletable by account admins. Every statement carves out KestrelDeploy; ReserveTheDeploymentRoleName closes the squatting hole that carve-out opens."
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/protect-platform.json")

  tags = local.standard_tags
}

resource "aws_organizations_policy_attachment" "protect_platform" {
  policy_id = aws_organizations_policy.protect_platform.id
  target_id = local.root_id
}

# --- Zone layers: attached where the zone's meaning differs ------------------

resource "aws_organizations_policy" "network_denies" {
  name        = "network-denies"
  description = "No own way out (v4 AND v6), no public addresses, VPCs from IPAM only (the Null condition denies a CreateVpc where no pool was specified at all — the actual failure mode, a hand-carved CIDR)."
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/network-denies.json")

  tags = local.standard_tags
}

resource "aws_organizations_policy_attachment" "network_denies_nonprod" {
  policy_id = aws_organizations_policy.network_denies.id
  target_id = local.workload_ou_ids["Non-Prod"]
}

resource "aws_organizations_policy_attachment" "network_denies_prod" {
  # Attached one working day after Non-Prod — the sequencing is in git
  # history; both attachments are steady state.
  policy_id = aws_organizations_policy.network_denies.id
  target_id = local.workload_ou_ids["Prod"]
}

resource "aws_organizations_policy_attachment" "network_denies_exceptions" {
  # Exceptions is still a Workloads zone — an exception is a NARROWED
  # deny registered in exceptions.yaml, never a bypass of the zone layer.
  policy_id = aws_organizations_policy.network_denies.id
  target_id = local.workload_ou_ids["Exceptions"]
}

resource "aws_organizations_policy" "sandbox_denies" {
  name        = "sandbox-denies"
  description = "Sandbox bounded by service and blast radius. An SCP cannot cap a bill — spend is detective: an AWS Budgets action per account plus the expiry-tag clean-up."
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/sandbox-denies.json")

  tags = local.standard_tags
}

resource "aws_organizations_policy_attachment" "sandbox_denies" {
  policy_id = aws_organizations_policy.sandbox_denies.id
  target_id = local.top_ou_ids["Sandbox"]
}

# Transitional deliberately carries NOTHING beyond the org-root inherited
# set — graduation criteria (root swept, ap-southeast-4 opt-in confirmed,
# observed usage reconciled) live with the factory baseline (Vending).
