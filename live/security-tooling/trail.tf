# Accounts step 5 registered it; Logging & Monitoring step 2 configures
# what it records — the organisation trail.
#
# Owned by security-tooling (the delegated CloudTrail admin), delivered to
# log-archive — management versus usage privilege, and neither is the org
# root. It runs ALONGSIDE Organisation's interim trail for an overlap
# window, is proved to cover its scope by comparing delivered events, then
# the interim trail is stopped with its bucket kept and the retirement
# recorded (docs/registers/interim-trail-retirement.md). Cut over only
# AFTER the org trail's first digest file lands — a gap between trails is
# the one hole that can never be backfilled.
#
# Three event categories, not one (Monitoring decision 2): for this
# company the threat is not someone changing configuration, it's someone
# READING THE DATA through a private path with valid credentials.
# CloudTrail Lake is declined — it duplicates the archive at Lake prices,
# Athena already queries the evidence plane (athena.tf), and the service
# entered maintenance mode in March 2026.

resource "aws_cloudtrail" "org" {
  name = "kestrel-org"

  s3_bucket_name = local.logs_bucket_name
  kms_key_id     = local.logs_kms_alias_arn

  is_organization_trail      = true # every account, existing and future
  is_multi_region_trail      = true
  enable_log_file_validation = true # digest files prove logs weren't altered

  # 1. Management events — the control plane, on by default and free.
  advanced_event_selector {
    name = "management-events"

    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }

  # 2. Data events — S3 object-level reads and writes, SCOPED to the
  #    PROTECTED buckets. Estate-wide data events on a hot bucket is the
  #    budget flip named in decision 2: narrow to write events plus
  #    targeted read prefixes, risk accepted in the register.
  advanced_event_selector {
    name = "data-events-protected-buckets"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }

    field_selector {
      field       = "resources.ARN"
      starts_with = ["arn:aws:s3:::kestrel-protected-"]
    }
  }

  # 3. Network activity events — VPC endpoint calls, so the private path
  #    is recorded rather than assumed.
  advanced_event_selector {
    name = "network-activity-events"

    field_selector {
      field  = "eventCategory"
      equals = ["NetworkActivity"]
    }
  }

  tags = local.standard_tags
}
