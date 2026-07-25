# Logging & Monitoring step 6 — the SOC seam.
#
# Security Lake normalises every source to OCSF and writes Parquet to S3.
# THE CONTRACT WITH THE PROVIDER IS A SCHEMA, NOT A PRODUCT (decision 5):
# agreeing OCSF rather than a tool is what lets the SIEM behind it be
# replaced without re-plumbing every source.
#
# There is still no native Sentinel connector for Security Lake, so a
# Lambda ships Parquet to an Event Hub and the provider's DCR takes it
# from there. Everything up to and including the Event Hub is Kestrel's;
# everything after is the provider's, and THE SLA MEASURES THAT HANDOFF
# POINT. Flip: Microsoft ships a native connector, the Lambda retires,
# the OCSF contract is unchanged — which is why OCSF was the decision.
#
# Enabled by the DELEGATED ADMIN, never the management account: done
# backwards it half-enables and the rollback is manual.
#
# DELEGATED HERE, NOT TO security-tooling (Accounts decision 2): the Lake
# IS retained log data, so it lands with the other immutable logs rather
# than with the tools that read them. The account that holds the record
# still never runs the tools.
#
# What crosses the seam is the operations plane. The evidence plane is
# the Object-Locked archive beside this (main.tf) — Sentinel's data-lake
# tier holds a copy at most, never the record.

resource "aws_securitylake_data_lake" "this" {
  meta_store_manager_role_arn = aws_iam_role.security_lake.arn

  configuration {
    region = "ap-southeast-2"

    encryption_configuration {
      kms_key_id = aws_kms_key.security_lake.id
    }

    lifecycle_configuration {
      transition {
        days          = 365 # matches the archive's hot window
        storage_class = "GLACIER"
      }

      expiration {
        days = 2555 # 7 years — the same clock as the sink
      }
    }
  }

  tags = local.standard_tags
}

# The native OCSF sources — trail, VPC flow logs, Route 53 queries and
# WAF, plus Security Hub findings. Each is org-wide; accounts joining
# later are covered because the source names the org, not a list of
# accounts.
#
# THE LAKE COLLECTS AT SOURCE, IN PARALLEL WITH ARCHIVE DELIVERY — never
# by copying the archive bucket (Monitoring decision 5). A
# bucket-to-bucket copy would be a second record to keep honest, not a
# shortcut: two pipelines that must be proved identical rather than one
# source feeding two subscribers.
#
# Network Firewall is deliberately absent: it is NOT a native Lake
# source, which is why it takes an S3 connector instead
# (security-tooling/connectors.tf).
resource "aws_securitylake_aws_log_source" "this" {
  for_each = toset([
    "ROUTE53",
    "VPC_FLOW",
    "SH_FINDINGS",
    "CLOUD_TRAIL_MGMT",
    "WAF",
  ])

  source {
    regions     = ["ap-southeast-2", "ap-southeast-4"]
    source_name = each.key
  }

  depends_on = [aws_securitylake_data_lake.this]
}

# The provider reads the Lake through a subscriber, not a bucket policy —
# so revoking access at contract end is deleting one resource.
resource "aws_securitylake_subscriber" "soc" {
  subscriber_name        = "kestrel-managed-soc"
  subscriber_description = "The managed SOC's Sentinel — reads OCSF Parquet, writes nothing."
  access_type            = "S3"

  source {
    aws_log_source_resource {
      source_name    = "CLOUD_TRAIL_MGMT"
      source_version = "2.0"
    }
  }

  subscriber_identity {
    external_id = local.soc_external_id
    principal   = local.soc_account_id
  }

  tags = local.standard_tags

  depends_on = [aws_securitylake_aws_log_source.this]
}

# --- Supporting IAM and KMS --------------------------------------------------

data "aws_iam_policy_document" "security_lake_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["securitylake.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "security_lake" {
  name               = "kestrel-security-lake-meta-store"
  assume_role_policy = data.aws_iam_policy_document.security_lake_assume.json

  tags = local.standard_tags
}

resource "aws_iam_role_policy_attachment" "security_lake" {
  role       = aws_iam_role.security_lake.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSecurityLakeMetastoreManager"
}

# The subscriber grants S3 access to the OCSF Parquet; the KEY policy is
# what makes it readable. Without this the SOC's Sentinel sees objects it
# is authorised for and cannot decrypt any of them.
data "aws_iam_policy_document" "security_lake_key" {
  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }
  }

  statement {
    sid       = "LakeServiceUse"
    actions   = ["kms:GenerateDataKey*", "kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["securitylake.amazonaws.com"]
    }
  }

  # Read only — the provider decrypts the record, never re-encrypts it.
  statement {
    sid       = "SocSubscriberDecrypt"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.soc_account_id}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [local.soc_external_id]
    }
  }
}

resource "aws_kms_key" "security_lake" {
  description             = "SSE-KMS for the Security Lake OCSF store"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = data.aws_iam_policy_document.security_lake_key.json

  tags = local.standard_tags
}

resource "aws_kms_alias" "security_lake" {
  name          = "alias/kestrel-security-lake"
  target_key_id = aws_kms_key.security_lake.key_id
}
