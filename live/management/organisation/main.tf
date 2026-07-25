# Accounts step 1 — adopt, then shape.
#
# Bootstrap already made the org (Organisation's console session created
# it), so the organisation is IMPORTED, never created. A plan that shows
# the organisation being created rather than imported is the signal to
# stop.

import {
  to = aws_organizations_organization.this
  id = "o-kestrel00id"
}

resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  # Enabling a policy TYPE attaches nothing; it only lets policy attach
  # later. SCP + TAG on since this part (Accounts); RCP + DECLARATIVE
  # added by the Guardrails PR — the sequencing lives in git history,
  # since the organisation is one resource and this file is its home.
  # (live/management/policies/enable.tf documents the same call.)
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
    "RESOURCE_CONTROL_POLICY", # Guardrails step 4 — decision 3
    "DECLARATIVE_POLICY_EC2",  # Guardrails step 4 — decision 1
  ]

  # Trusted access grants reach to a SERVICE, never a human — delegating
  # admin to an account is a second, separate registration (delegation.tf).
  aws_service_access_principals = [
    "account.amazonaws.com",
    "access-analyzer.amazonaws.com",
    "backup.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "fms.amazonaws.com",
    "guardduty.amazonaws.com",
    "iam.amazonaws.com", # centralised root access management (Organisation step 4)
    "ipam.amazonaws.com",
    "networkmanager.amazonaws.com",
    "ram.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
  ]
}

# --- The OU tree — grouped by policy, not org chart (Accounts decision 1) ----
#
# Eight OUs at this part: six top-level plus Prod and Non-Prod under
# Workloads. Policy-Staging and Exceptions arrive with Guardrails, the
# part whose policies define them. kestrel-management sits in NO OU — the
# org root is not a member of the tree it owns.

resource "aws_organizations_organizational_unit" "top" {
  for_each = toset([
    "Security",       # delegated admin + the log sink live here
    "Infrastructure", # shared fabric: network, shared-services
    "Workloads",      # customer-facing, split Prod / Non-Prod below
    "Sandbox",        # loose policy, no network, still logged — detection is inherited
    "Transitional",   # brownfield holding area — detective-only
    "Suspended",      # quarantine — deny-all attaches later
  ])

  name      = each.key
  parent_id = aws_organizations_organization.this.roots[0].id

  tags = local.standard_tags
}

resource "aws_organizations_organizational_unit" "workloads" {
  for_each = toset(["Prod", "Non-Prod"])

  name      = each.key
  parent_id = aws_organizations_organizational_unit.top["Workloads"].id

  tags = local.standard_tags
}
