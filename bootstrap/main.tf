# Steps 7–8 — the state backend, migrated into itself.
#
# Built in shared-services, NEVER the management account: state carries
# secrets and the org root stays minimal. One state bucket, one Region on
# purpose — one state object is what makes a lock mean anything.
# Cross-Region replication to ap-southeast-4 covers durability; restoring
# the ability to *apply* is a documented DR rebuild (docs/runbooks/).
#
# This stack starts on local state; after the first apply the backend block
# below is added and `terraform init -migrate-state` closes the
# chicken-and-egg. The local terraform.tfstate is then DELETED, not
# ignored — a stale copy is the estate's most sensitive object on a laptop.

terraform {
  backend "s3" {
    bucket       = "kes-shared-syd-tfstate"
    key          = "bootstrap/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true # native S3 locking — no DynamoDB table (>= 1.10)
  }
}

# --- Encryption keys ---------------------------------------------------------

data "aws_caller_identity" "shared_services" {
  provider = aws.shared_services
}

# The account-root admin statement is the standard KMS pattern: it
# delegates key administration to IAM in the key's own account; the
# wildcard resource inside a KEY policy scopes to the key itself.
data "aws_iam_policy_document" "state_key" {
  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.shared_services.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "state" {
  provider = aws.shared_services

  description             = "SSE-KMS for the Terraform state backend"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.state_key.json

  tags = local.standard_tags
}

resource "aws_kms_alias" "state" {
  provider = aws.shared_services

  name          = "alias/kes-shared-syd-tfstate"
  target_key_id = aws_kms_key.state.key_id
}

resource "aws_kms_key" "state_replica" {
  provider = aws.shared_services_melbourne

  description             = "SSE-KMS for the state backend replica (ap-southeast-4)"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.state_key.json

  tags = local.standard_tags
}

# --- The state bucket --------------------------------------------------------

resource "aws_s3_bucket" "state" {
  provider = aws.shared_services

  bucket              = "kes-shared-syd-tfstate"
  object_lock_enabled = true # cannot be added to an existing bucket

  tags = local.standard_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  provider = aws.shared_services

  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled" # rollback from version history — drilled and timed, not assumed
  }
}

resource "aws_s3_bucket_object_lock_configuration" "state" {
  provider = aws.shared_services

  bucket = aws_s3_bucket.state.id

  rule {
    default_retention {
      # GOVERNANCE, 30 days — a rollback window, NOT COMPLIANCE: state can
      # hold a provider-generated secret, and COMPLIANCE makes it unpurgeable.
      mode = "GOVERNANCE"
      days = 30
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  provider = aws.shared_services

  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  provider = aws.shared_services

  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  provider = aws.shared_services

  bucket = aws_s3_bucket.state.id

  rule {
    id     = "housekeeping"
    status = "Enabled"

    # State objects are small and precious — nothing expires. This rule
    # only clears failed multipart uploads and thins noncurrent versions
    # well outside the Object Lock rollback window.
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 365 # far beyond the 30-day GOVERNANCE window
    }

    filter {}
  }
}

# --- Cross-Region replication to Melbourne -----------------------------------

resource "aws_s3_bucket" "state_replica" {
  provider = aws.shared_services_melbourne

  bucket              = "kes-shared-mel-tfstate"
  object_lock_enabled = true # replication of locked objects requires it on both ends

  tags = local.standard_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state_replica" {
  provider = aws.shared_services_melbourne

  bucket = aws_s3_bucket.state_replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_replica" {
  provider = aws.shared_services_melbourne

  bucket = aws_s3_bucket.state_replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state_replica.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state_replica" {
  provider = aws.shared_services_melbourne

  bucket = aws_s3_bucket.state_replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state_replica" {
  provider = aws.shared_services_melbourne

  bucket = aws_s3_bucket.state_replica.id

  rule {
    id     = "housekeeping"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    filter {}
  }
}

data "aws_iam_policy_document" "replication_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "replication" {
  statement {
    sid       = "ReadSource"
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
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
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }

  statement {
    sid = "WriteReplica"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]
    resources = ["${aws_s3_bucket.state_replica.arn}/*"]
  }

  statement {
    sid       = "DecryptSource"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.state.arn]
  }

  statement {
    sid       = "EncryptReplica"
    actions   = ["kms:Encrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.state_replica.arn]
  }
}

resource "aws_iam_role" "replication" {
  provider = aws.shared_services

  name               = "kes-shared-tfstate-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_assume.json

  tags = local.standard_tags
}

resource "aws_iam_role_policy" "replication" {
  provider = aws.shared_services

  name   = "replication"
  role   = aws_iam_role.replication.id
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_s3_bucket_replication_configuration" "state" {
  provider = aws.shared_services

  depends_on = [
    aws_s3_bucket_versioning.state,
    aws_s3_bucket_versioning.state_replica,
  ]

  bucket = aws_s3_bucket.state.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "durability-to-melbourne"
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
      bucket        = aws_s3_bucket.state_replica.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.state_replica.arn
      }
    }
  }
}
