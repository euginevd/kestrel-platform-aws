# Accounts step 5 — the organisation trail.
#
# Owned by security-tooling (the delegated CloudTrail admin), delivered to
# log-archive — management versus usage privilege, and neither is the org
# root. It runs ALONGSIDE Organisation's interim trail for an overlap
# window, is proved to cover its scope by comparing delivered events, then
# the interim trail is stopped with its bucket kept and the retirement
# recorded (docs/registers/interim-trail-retirement.md).

resource "aws_cloudtrail" "org" {
  name = "kestrel-org"

  s3_bucket_name = local.logs_bucket_name
  kms_key_id     = local.logs_kms_alias_arn

  is_organization_trail      = true # every account, existing and future
  is_multi_region_trail      = true
  enable_log_file_validation = true # digest files prove logs weren't altered

  tags = local.standard_tags
}
