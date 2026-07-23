# Identity step 2 — map groups to OU scopes, and DERIVE assignments from
# the map. An account moved between OUs gains and loses the correct
# assignments on the next plan, with no per-account resource edited — the
# NFR this leaf owes the Account Factory.
#
# Every assignment binds a set to a GROUP, never a user: membership is
# governed in Entra, from HR. The elevation groups (sg-aws-*-jit) appear
# in NO standing grant — they arrive via SCIM only while a PIM activation
# is live, and the assignment below is what the activated group resolves
# to. Prod admin is reachable only that way.
#
# log-archive deliberately gets NO assignment block at all — the account
# holding every log is one nobody can log into. That absence is the
# control, not an oversight.

locals {
  ou_grants = {
    "Workloads/Non-Prod" = {
      "sg-aws-workload-engineers" = "WorkloadDeploy"
      "sg-aws-platform-readonly"  = "PlatformReadOnly"
    }
    "Workloads/Prod" = {
      "sg-aws-platform-readonly" = "PlatformReadOnly"
      "sg-aws-prod-admin-jit"    = "PlatformAdmin" # PIM-populated; empty between activations
    }
    "Security" = {
      "sg-aws-security-audit"     = "SecurityAudit"
      "sg-aws-security-admin-jit" = "PlatformAdmin" # PIM-populated
    }
    "Infrastructure" = {
      "sg-aws-platform-admin-jit" = "PlatformAdmin" # PIM-populated
      "sg-aws-platform-readonly"  = "PlatformReadOnly"
    }
  }
}

# --- Resolve OU names to accounts --------------------------------------------

data "aws_organizations_organization" "this" {}

data "aws_organizations_organizational_units" "top" {
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

locals {
  top_ou_ids = {
    for ou in data.aws_organizations_organizational_units.top.children : ou.name => ou.id
  }
}

data "aws_organizations_organizational_units" "workloads" {
  parent_id = local.top_ou_ids["Workloads"]
}

locals {
  ou_ids = merge(
    local.top_ou_ids,
    {
      for ou in data.aws_organizations_organizational_units.workloads.children :
      "Workloads/${ou.name}" => ou.id
    },
  )
}

data "aws_organizations_organizational_unit_descendant_accounts" "grant" {
  for_each = local.ou_grants

  parent_id = local.ou_ids[each.key]
}

# --- Resolve group names to the SCIM-provisioned identities ------------------

locals {
  all_groups = toset(flatten([for ou, grants in local.ou_grants : keys(grants)]))
}

data "aws_identitystore_group" "this" {
  for_each = local.all_groups

  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.key # must be a cloud-native Entra security group, direct members only — SCIM does not flatten nesting
    }
  }
}

# --- Derive the assignments --------------------------------------------------

locals {
  assignments = {
    for a in flatten([
      for ou, grants in local.ou_grants : [
        for group, pset in grants : [
          for acct in data.aws_organizations_organizational_unit_descendant_accounts.grant[ou].accounts : {
            key        = "${ou}/${group}/${acct.id}"
            group      = group
            pset       = pset
            account_id = acct.id
          }
        ]
      ]
    ]) : a.key => a
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.assignments

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.pset].arn

  principal_id   = data.aws_identitystore_group.this[each.value.group].group_id
  principal_type = "GROUP" # membership governed in Entra, from HR

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}
