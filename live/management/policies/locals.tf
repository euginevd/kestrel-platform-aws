locals {
  standard_tags = {
    DataClassification = "OFFICIAL"
    Owner              = "security-team@kestrel.com.au"
    CostCentre         = "CC-SECURITY"
    Application        = "landing-zone"
  }

  # The org ID is a Terraform-injected LITERAL, never ${aws:PrincipalOrgID}
  # — the variable resolves to the caller's own org ID, so the condition
  # compares a value to itself and silently permits the world while
  # reading as correct.
  org_id = "o-kestrel00id"
}

# OU targets, resolved by name — this leaf attaches policy; the tree
# itself belongs to live/management/organisation/.
data "aws_organizations_organization" "this" {}

data "aws_organizations_organizational_units" "top" {
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

data "aws_organizations_organizational_units" "workloads" {
  parent_id = local.top_ou_ids["Workloads"]
}

locals {
  root_id = data.aws_organizations_organization.this.roots[0].id

  top_ou_ids = {
    for ou in data.aws_organizations_organizational_units.top.children : ou.name => ou.id
  }

  workload_ou_ids = {
    for ou in data.aws_organizations_organizational_units.workloads.children : ou.name => ou.id
  }
}
