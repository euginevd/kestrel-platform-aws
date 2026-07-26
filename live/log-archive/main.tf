# Logging & Monitoring step 1 — the Object-Locked sink, the evidence plane.
#
# Managed by Security Tooling, sink in Log Archive, queried by Athena, no
# human access (Accounts decision 2). The split is management versus usage
# privilege: the account that can read all logs is not the account that
# runs the tools, and neither is the org root.
#
# This is the EVIDENCE plane and it is ours: it must outlive the SOC
# contract, so the provider's Sentinel (the operations plane) holds a
# copy at most, never the record (Monitoring decision 1).
#
# This bucket carries the evidence convention for the whole series:
# exports land under s3://kestrel-log-archive/irap/phase-<n>/, each filed
# against the ISM controls it satisfies.

# Object Lock is only half the integrity story (Monitoring decision 1):
# an archive encrypted with a key someone can disable is deletable by
# another name. So the CMK is customer-managed HERE, rotated annually,
# and its policy separates administration from use — scheduling its
# deletion is itself an alarm (security-tooling/alarms.tf).
resource "aws_kms_key" "logs" {
  description             = "SSE-KMS for the org-trail and Config sink"
  enable_key_rotation     = true
  rotation_period_in_days = 365
  deletion_window_in_days = 30

  policy = data.aws_iam_policy_document.logs_key.json

  tags = local.standard_tags
}

resource "aws_kms_alias" "logs" {
  name          = "alias/kestrel-org-logs"
  target_key_id = aws_kms_key.logs.key_id
}

data "aws_caller_identity" "this" {}

data "aws_iam_policy_document" "logs_key" {
  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }
  }

  # USE, not administration: security-tooling queries the archive through
  # Athena and so must decrypt, but holds no kms:PutKeyPolicy,
  # kms:ScheduleKeyDeletion or kms:DisableKey. NOBODY HOLDS BOTH — that
  # is the whole point of the split (Monitoring decision 1).
  statement {
    sid = "SecurityToolingUseOnly"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
    ]

    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.security_tooling_account_id}:root"]
    }
  }

  # Every service the BUCKET POLICY admits as a writer must also be able
  # to encrypt, or delivery fails silently — the bucket accepts the
  # principal and KMS refuses the key, which reads as a source that
  # simply never wrote. Keep this list in step with the writers in
  # data.aws_iam_policy_document.logs_bucket below.
  statement {
    sid       = "LogSourceEncrypt"
    actions   = ["kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com",
        "config.amazonaws.com",
        "delivery.logs.amazonaws.com", # VPC flow logs (Monitoring step 4)
        "route53.amazonaws.com",       # Resolver query logs (Monitoring step 4)
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceOrgID"
      values   = [local.org_id]
    }
  }
}

# --- The sink ----------------------------------------------------------------

resource "aws_s3_bucket" "logs" {
  bucket              = "kestrel-org-cloudtrail-ap-southeast-2"
  object_lock_enabled = true # create-time only — cannot be added later

  tags = local.standard_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    default_retention {
      # COMPLIANCE with the records-schedule retention — chosen once and
      # effectively irreversible; nobody, including root, shortens it.
      # Contrast the state bucket's GOVERNANCE/30d: state can hold a
      # provider-generated secret and must stay purgeable.
      mode  = "COMPLIANCE"
      years = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.logs.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Two clocks, set beside the lock so they're visibly one policy — and they
# MUST NOT DISAGREE: a lifecycle that expires an object the lock still
# protects fails quietly. 2555 days = 7 years = the Object Lock retention.
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "two-clocks"
    status = "Enabled"

    transition {
      days          = 365 # 12 months hot and searchable (ISM-1988) …
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555 # … then the 7-year tail (ISM-0859; NAA disposal authority per ISM-1989)
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    filter {}
  }
}

# --- Bucket policy: only the trail and Config may write ----------------------

data "aws_iam_policy_document" "logs_bucket" {
  statement {
    sid       = "TrailAclCheck"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceOrgID"
      values   = [local.org_id]
    }
  }

  statement {
    sid       = "TrailWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/AWSLogs/${local.org_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    # Scoped by SourceArn AND SourceOrgID — a workload admin still cannot
    # write or erase.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "ConfigWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/AWSLogs/*"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceOrgID"
      values   = [local.org_id]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  # Logging & Monitoring step 4 — the platform-enforced sources. Flow
  # logs and Resolver query logs are written by the VPC module in every
  # account (modules/account-baseline/network/), so the writer is the
  # service, scoped to the org: no account-level toggle exists to turn
  # them off, and no account outside the org can write here.
  statement {
    sid       = "PlatformSourceWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]

    principals {
      type = "Service"
      identifiers = [
        "delivery.logs.amazonaws.com", # VPC flow logs
        "route53.amazonaws.com",       # Resolver query logs
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceOrgID"
      values   = [local.org_id]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  # Session recordings are the one platform source written by an IAM
  # PRINCIPAL rather than a service: Session Manager uploads the
  # transcript as the instance's own role in the member account
  # (modules/account-baseline/sessions.tf). PrincipalOrgID is what keeps
  # that from meaning "any role anywhere", and the prefix confines it to
  # the one path — a role that can write session-recordings/ still cannot
  # touch the trail's objects.
  statement {
    sid       = "SessionRecordingWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/session-recordings/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [local.org_id]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_bucket.json
}

# --- Notifications out to the connector queues -------------------------------

# Monitoring step 7: the Sentinel connectors read THIS bucket — the
# record lands once and is read twice, rather than a second pipeline
# nobody reconciles. The queues are owned by security-tooling; this end
# only announces that an object arrived.
#
# One notification per prefix, not one for the whole bucket: a connector
# receiving every object in the archive would re-ingest the trail it
# already gets natively through the Lake.
resource "aws_s3_bucket_notification" "connectors" {
  bucket = aws_s3_bucket.logs.id

  dynamic "queue" {
    for_each = local.connector_notifications

    content {
      id            = "connector-${queue.key}"
      queue_arn     = "arn:aws:sqs:ap-southeast-2:${local.security_tooling_account_id}:kestrel-connector-${queue.key}"
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = queue.value
    }
  }
}
