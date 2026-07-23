# Accounts step 2 — vend the four remaining core accounts.
#
# The OU is the only field a human types — name and email derive from ONE
# map key, so they cannot drift. No root email is hand-written anywhere.
# (kestrel-shared-services predates this leaf — bootstrap vended it; the
# factory adopts it in live/management/accounts/.)

locals {
  core_accounts = {
    log-archive      = { parent_ou = "Security" }       # immutable org-trail + Config sink, no human access
    security-tooling = { parent_ou = "Security" }       # delegated admin: GuardDuty, Security Hub, Config, Access Analyzer
    identity         = { parent_ou = "Security" }       # delegated admin: IAM Identity Center — grants access, watches nothing
    network          = { parent_ou = "Infrastructure" } # Cloud WAN core network, egress, inspection, DNS — BOTH Regions, one account
  }
}

resource "aws_organizations_account" "core" {
  for_each = local.core_accounts

  name      = "kestrel-${each.key}"                 # name and email derive from
  email     = "root+${each.key}@aws.kestrel.com.au" #   ONE key, so they cannot drift
  parent_id = aws_organizations_organizational_unit.top[each.value.parent_ou].id

  tags = local.standard_tags

  lifecycle {
    prevent_destroy = true
  }
}

# --- Step 3 — alternate contacts: the same three DLs on every account --------

resource "aws_account_alternate_contact" "core" {
  for_each = {
    for pair in setproduct(keys(local.core_accounts), keys(local.alternate_contacts)) :
    "${pair[0]}-${pair[1]}" => { account = pair[0], type = pair[1] }
  }

  account_id             = aws_organizations_account.core[each.value.account].id
  alternate_contact_type = each.value.type
  email_address          = local.alternate_contacts[each.value.type].email
  name                   = local.alternate_contacts[each.value.type].name
  phone_number           = local.alternate_contacts[each.value.type].phone
  title                  = local.alternate_contacts[each.value.type].title
}
