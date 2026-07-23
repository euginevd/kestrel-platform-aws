locals {
  # The four standard tags — enforced in review by CKV_KES_1, backstopped
  # by the org tag policy once Guardrails lands.
  standard_tags = {
    DataClassification = "OFFICIAL"
    Owner              = "platform-team@kestrel.com.au"
    CostCentre         = "CC-PLATFORM"
    Application        = "landing-zone"
  }

  # Placeholder account IDs — this is a reference implementation; nothing
  # here refers to real infrastructure. Kept in accounts.json for the
  # pipeline's routing; repeated here for the roles bootstrap creates.
  management_account_id      = "123456789012"
  shared_services_account_id = "423456789012"
}
