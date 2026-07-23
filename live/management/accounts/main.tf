# The account directory — Vending decision 2: one declared file per
# account, everything else derived. A reviewer reads a vending PR in
# seconds: this account, this OU, this owner. CODEOWNERS on
# /live/management/ means a vending PR merges with platform AND security
# approval and a linked ticket, or not at all — the ticket holds the
# business approval, CODEOWNERS the technical one; a vending PR needs
# both.
#
# The same directory is the estate's inventory: every account the estate
# has gets an entry — the core four, shared-services, the brownfield ~20
# — so `list-accounts` and this directory reconcile one to one, with no
# entry-less accounts and no account-less entries.

locals {
  # Names that have ever been used — grows forever, never shrinks: an
  # email used for an account can never be used again, even after closure
  # and termination.
  retired_names = [
    "kestrel-vend-test", # the factory's own proof — vended and decommissioned (Vending steps 5–6)
  ]

  entries = {
    for f in fileset(path.module, "*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.module}/${f}"))
  }
}

# --- Resolve declared OU paths to IDs ----------------------------------------

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

# --- The factory: one module instance per declared entry ---------------------
#
# A malformed entry — unknown OU, missing owner, recycled name — fails
# the PLAN, not the apply: the ou_ids lookup errors on an unknown OU, the
# module's validations catch the rest.

module "account" {
  source = "../../../modules/account-factory"

  for_each = local.entries

  name                = each.value.name
  ou_id               = local.ou_ids[each.value.ou]
  owner               = each.value.owner
  purpose             = each.value.purpose
  request_ref         = each.value.request_ref
  data_classification = try(each.value.data_classification, "OFFICIAL")
  cost_centre         = try(each.value.cost_centre, "CC-PLATFORM")
  retired_names       = local.retired_names
}

# The birth baseline (modules/account-baseline) runs in-account through
# OrganizationAccountAccessRole — the pipeline instantiates it per vended
# account with that provider, KestrelDeploy first. When an entry declares
# a network tier, the baseline allocates the CIDR from the OU's IPAM pool
# and attaches the spoke to the Cloud WAN core network by segment tag
# (live/network/), so the first packet already crosses the inspected
# exit. No tier, no network — the correct state for Sandbox and service
# accounts.
#
# Decommissioning is the pipeline in reverse (Vending decision 4): export
# evidence WITH its ticket references to log-archive, move to Suspended,
# then CloseAccount via the central API — designed around the closure
# quota (10% of members per rolling 30 days) and the 90-day recoverable
# window, with lifecycle state asserted from the Organizations API.
