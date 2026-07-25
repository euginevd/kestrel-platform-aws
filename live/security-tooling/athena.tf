# Accounts decision 2 — searchable is a capability, not a setting.
#
# ISM-1988 wants event logs searchable for twelve months, and an
# Object-Locked bucket with no query layer is only "we can download
# them". Athena over the org-trail bucket with PARTITION PROJECTION —
# not CloudTrail Lake, which duplicates the ingest cost for logs already
# stored immutably. Correlation across accounts assumes a common clock:
# the Amazon Time Sync Service is that source (ISM-0988), on by default.

resource "aws_athena_workgroup" "logs" {
  name = "kestrel-log-queries"

  configuration {
    enforce_workgroup_configuration = true

    # A spend cap, because an unbounded scan of seven years of logs is a
    # self-inflicted incident (Monitoring decision 6). Partition
    # projection above keeps a well-written query small; this is what
    # stops a badly-written one. 200 GB — a query that needs more is one
    # worth a conversation before it runs.
    bytes_scanned_cutoff_per_query = 200 * 1024 * 1024 * 1024

    result_configuration {
      # Results are queries about evidence, not evidence — they land in a
      # prefix of the workgroup's own bucket in this account, not the sink.
      output_location = "s3://kestrel-security-athena-results/queries/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = aws_kms_key.athena_results.arn
      }
    }
  }

  tags = local.standard_tags
}

resource "aws_glue_catalog_database" "logs" {
  name = "kestrel_logs"
}

resource "aws_glue_catalog_table" "cloudtrail" {
  name          = "org_cloudtrail"
  database_name = aws_glue_catalog_database.logs.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "cloudtrail"

    # Partition projection: no crawler, no MSCK REPAIR — partitions are
    # computed from the key layout, so a query written today returns
    # events from any account and day without maintenance.
    "projection.enabled"        = "true"
    "projection.account.type"   = "injected"
    "projection.region.type"    = "enum"
    "projection.region.values"  = "ap-southeast-2,ap-southeast-4"
    "projection.date.type"      = "date"
    "projection.date.range"     = "2026/07/01,NOW"
    "projection.date.format"    = "yyyy/MM/dd"
    "storage.location.template" = "s3://kestrel-org-cloudtrail-ap-southeast-2/AWSLogs/o-kestrel00id/$${account}/CloudTrail/$${region}/$${date}"
  }

  partition_keys {
    name = "account"
    type = "string"
  }

  partition_keys {
    name = "region"
    type = "string"
  }

  partition_keys {
    name = "date"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://kestrel-org-cloudtrail-ap-southeast-2/AWSLogs/o-kestrel00id/"
    input_format  = "com.amazon.emr.cloudtrail.CloudTrailInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hive.hcatalog.data.JsonSerDe"
    }

    columns {
      name = "eventversion"
      type = "string"
    }

    columns {
      name = "useridentity"
      type = "struct<type:string,principalid:string,arn:string,accountid:string,username:string>"
    }

    columns {
      name = "eventtime"
      type = "string"
    }

    columns {
      name = "eventsource"
      type = "string"
    }

    columns {
      name = "eventname"
      type = "string"
    }

    columns {
      name = "awsregion"
      type = "string"
    }

    columns {
      name = "sourceipaddress"
      type = "string"
    }

    columns {
      name = "requestparameters"
      type = "string"
    }

    columns {
      name = "responseelements"
      type = "string"
    }
  }
}

# --- The results bucket ------------------------------------------------------

data "aws_caller_identity" "this" {}

data "aws_iam_policy_document" "athena_key" {
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

resource "aws_kms_key" "athena_results" {
  description             = "SSE-KMS for Athena query results"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.athena_key.json

  tags = local.standard_tags
}

resource "aws_s3_bucket" "athena_results" {
  bucket = "kestrel-security-athena-results"

  tags = local.standard_tags
}

resource "aws_s3_bucket_versioning" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.athena_results.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "expire-query-results"
    status = "Enabled"

    expiration {
      days = 90 # query results are working copies, never evidence
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    filter {}
  }
}
