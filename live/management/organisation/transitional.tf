# Accounts step 7 — adopt, never create.
#
# The ~60 brownfield accounts enrol LAST, into a transit OU carrying no
# policy — watched but not governed, covered by the trail and detective
# services the moment they join. Invitation and acceptance run from inside
# each account (the one step the pipeline cannot fully drive); this file
# adopts the result so the repo's inventory and the organisation's
# reality reconcile.
#
# They arrive with their names and their EXISTING root emails, unchanged —
# renaming is not enrolment. Three shown; the remaining entries follow the
# same shape, one line per account, all placeholder IDs.

locals {
  existing_accounts = {
    "523456789012" = { name = "kestrel-legacy-crm", root_email = "aws-crm@kestrel.com.au" }
    "623456789012" = { name = "kestrel-legacy-data", root_email = "cloud-admin@kestrel.com.au" }
    "723456789012" = { name = "kestrel-legacy-web", root_email = "webops@kestrel.com.au" }
    # … the rest of the ~60, by account ID
  }
}

import {
  for_each = local.existing_accounts

  to = aws_organizations_account.brownfield[each.key]
  id = each.key
}

resource "aws_organizations_account" "brownfield" {
  for_each = local.existing_accounts

  name      = each.value.name
  email     = each.value.root_email # their EXISTING root email, unchanged
  parent_id = aws_organizations_organizational_unit.top["Transitional"].id

  # Standard tags at enrolment are the platform's stewardship defaults —
  # graduation (Vending) replaces Owner and CostCentre with the account's
  # real values once observed usage names them.
  tags = local.standard_tags

  lifecycle {
    prevent_destroy = true # never create — or close — a live account
  }
}
