locals {
  standard_tags = {
    DataClassification = "OFFICIAL"
    Owner              = "security-team@kestrel.com.au"
    CostCentre         = "CC-SECURITY"
    Application        = "landing-zone"
  }

  org_id = "o-kestrel00id"

  # The sink lives in log-archive (its own leaf, its own state). Cross-leaf
  # references are name-shaped and stable — bucket names and key aliases,
  # never generated IDs — so leaves stay independently appliable.
  logs_bucket_name   = "kestrel-org-cloudtrail-ap-southeast-2"
  logs_kms_alias_arn = "arn:aws:kms:ap-southeast-2:223456789012:alias/kestrel-org-logs"
}
