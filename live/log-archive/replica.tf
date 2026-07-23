# Cross-Region replica in Melbourne — the copy an assessor would reach
# for if Sydney were the Region that was lost.
#
# The replica's lifecycle is ALIGNED TO THE PRIMARY — the same two clocks.
# This is FIND-012's fix (Assessment, PR #214): the original replica
# carried the 12-month Glacier transition and no expiry rule at all, so
# ISM-0859 retention was provable in Sydney and unproven on the copy.
# The two-clocks-must-not-disagree care applies to every copy, not just
# the original.

data "aws_iam_policy_document" "replica_key" {
  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "logs_replica" {
  provider = aws.melbourne

  description             = "SSE-KMS for the log sink replica (ap-southeast-4)"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.replica_key.json

  tags = local.standard_tags
}

resource "aws_s3_bucket" "logs_replica" {
  provider = aws.melbourne

  bucket              = "kestrel-org-cloudtrail-ap-southeast-4"
  object_lock_enabled = true

  tags = local.standard_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "logs_replica" {
  provider = aws.melbourne

  bucket = aws_s3_bucket.logs_replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "logs_replica" {
  provider = aws.melbourne

  bucket = aws_s3_bucket.logs_replica.id

  rule {
    default_retention {
      mode  = "COMPLIANCE"
      years = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_replica" {
  provider = aws.melbourne

  bucket = aws_s3_bucket.logs_replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.logs_replica.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "logs_replica" {
  provider = aws.melbourne

  bucket = aws_s3_bucket.logs_replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_replica" {
  provider = aws.melbourne

  bucket = aws_s3_bucket.logs_replica.id

  rule {
    id     = "two-clocks" # aligned to the primary — FIND-012 / PR #214
    status = "Enabled"

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    filter {}
  }
}

# --- Replication -------------------------------------------------------------

data "aws_iam_policy_document" "logs_replication_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "logs_replication" {
  statement {
    sid       = "ReadSource"
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [aws_s3_bucket.logs.arn]
  }

  statement {
    sid = "ReadObjects"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold",
    ]
    resources = ["${aws_s3_bucket.logs.arn}/*"]
  }

  statement {
    sid = "WriteReplica"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${aws_s3_bucket.logs_replica.arn}/*"]
  }

  statement {
    sid       = "DecryptSource"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.logs.arn]
  }

  statement {
    sid       = "EncryptReplica"
    actions   = ["kms:Encrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.logs_replica.arn]
  }
}

resource "aws_iam_role" "logs_replication" {
  name               = "kestrel-log-archive-replication"
  assume_role_policy = data.aws_iam_policy_document.logs_replication_assume.json

  tags = local.standard_tags
}

resource "aws_iam_role_policy" "logs_replication" {
  name   = "replication"
  role   = aws_iam_role.logs_replication.id
  policy = data.aws_iam_policy_document.logs_replication.json
}

resource "aws_s3_bucket_replication_configuration" "logs" {
  depends_on = [
    aws_s3_bucket_versioning.logs,
    aws_s3_bucket_versioning.logs_replica,
  ]

  bucket = aws_s3_bucket.logs.id
  role   = aws_iam_role.logs_replication.arn

  rule {
    id     = "durability-to-melbourne" # stays onshore — evidence never leaves the residency boundary
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Disabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.logs_replica.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.logs_replica.arn
      }
    }
  }
}
