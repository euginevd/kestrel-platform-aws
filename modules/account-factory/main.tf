# The factory — Vending decision 1: a thin Terraform pattern over the
# Organizations APIs already in the platform repo, not AFT (which
# requires Control Tower and is real machinery to operate).
#
# Everything is DERIVED from the declared entry — email from the
# Organisation scheme, tags from the standard — so anything the requester
# can't set can't drift. CreateAccount runs one at a time: twenty
# accounts is a sequence, not a fan-out; the org's account limit is a
# service quota raised ahead of need.

resource "aws_organizations_account" "this" {
  name      = var.name
  email     = "root+${trimprefix(var.name, "kestrel-")}@aws.kestrel.com.au" # never in the schema — derived, never recycled
  parent_id = var.ou_id

  # Centralised root access management is on: the account is born without
  # root credentials. Melbourne opt-in, default-VPC deletion, contacts and
  # the KestrelDeploy role run in-account via the birth baseline
  # (modules/account-baseline) — only what OU inheritance can't reach.

  tags = {
    DataClassification = var.data_classification
    Owner              = var.owner
    CostCentre         = var.cost_centre
    Application        = "landing-zone"
    Purpose            = var.purpose
    RequestRef         = var.request_ref # the walkable chain to the business record
  }

  lifecycle {
    prevent_destroy = true # decommissioning is deliberate: export evidence, move to Suspended, CloseAccount — never a destroy

    precondition {
      condition     = !contains(var.retired_names, var.name)
      error_message = "This account name has been used before — root emails are never reusable, and a decommissioned account's name retires with it."
    }
  }
}
