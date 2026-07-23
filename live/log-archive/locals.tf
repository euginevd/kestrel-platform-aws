locals {
  standard_tags = {
    DataClassification = "OFFICIAL"
    Owner              = "security-team@kestrel.com.au"
    CostCentre         = "CC-SECURITY"
    Application        = "landing-zone"
  }

  org_id                = "o-kestrel00id"
  management_account_id = "123456789012"
  trail_arn             = "arn:aws:cloudtrail:ap-southeast-2:323456789012:trail/kestrel-org" # owned by security-tooling
}
