# Logging & Monitoring step 7 — the sources the Lake cannot carry.
#
# ONE SQS QUEUE PER LOG TYPE AND PER S3 PATH, or the Sentinel S3
# connectors silently miss data (decision 6). The queues are platform
# Terraform, not provider clickwork — a queue someone created by hand in
# a console is a queue nobody can prove the shape of.
#
# THE CONNECTORS READ THE ARCHIVE BUCKET ITSELF, on notifications from
# these queues — the "lands once" rule made literal. The provider reads a
# copy of the record rather than running a parallel pipeline nobody
# reconciles: one place the log landed, two readers of it.
#
# Network Firewall is here rather than in the Lake because it is not a
# native Lake source (log-archive/securitylake.tf). CloudWatch
# application logs need Microsoft's converter Lambda before the connector
# will accept them; Kestrel runs it rather than asking the provider to,
# because the converter failing is Kestrel's silence to detect
# (alarms.tf).

resource "aws_sqs_queue" "connector_dlq" {
  for_each = local.connector_sources

  name                      = "kestrel-connector-${each.key}-dlq"
  kms_master_key_id         = aws_kms_key.connectors.id
  message_retention_seconds = 1209600 # 14 days — long enough to notice and replay

  tags = local.standard_tags
}

resource "aws_sqs_queue" "connector" {
  for_each = local.connector_sources

  name              = "kestrel-connector-${each.key}"
  kms_master_key_id = aws_kms_key.connectors.id

  # The connector polls; a message it never manages to hand over lands in
  # the DLQ, whose depth is itself an alarm rather than a silent loss.
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.connector_dlq[each.key].arn
    maxReceiveCount     = 5
  })

  tags = local.standard_tags
}

# The archive bucket notifies the queue that an object landed; the
# connector reads the queue rather than listing the bucket, which is what
# keeps ingestion lag bounded as the archive grows past seven years.
#
# The notifying bucket lives in LOG-ARCHIVE, not here — so SourceAccount
# is that account, and SourceArn pins it to the one bucket. A queue that
# would accept notifications from any bucket in any account is a queue
# anyone can inject into.
data "aws_iam_policy_document" "connector_queue" {
  for_each = local.connector_sources

  statement {
    sid       = "AllowArchiveNotification"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.connector[each.key].arn]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.log_archive_account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:s3:::${local.logs_bucket_name}"]
    }
  }

  statement {
    sid     = "AllowSocRead"
    actions = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]

    resources = [aws_sqs_queue.connector[each.key].arn]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.soc_account_id}:root"]
    }
  }
}

resource "aws_sqs_queue_policy" "connector" {
  for_each = local.connector_sources

  queue_url = aws_sqs_queue.connector[each.key].id
  policy    = data.aws_iam_policy_document.connector_queue[each.key].json
}

resource "aws_kms_key" "connectors" {
  description             = "SSE-KMS for the Sentinel connector queues"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = local.standard_tags
}

resource "aws_kms_alias" "connectors" {
  name          = "alias/kestrel-connectors"
  target_key_id = aws_kms_key.connectors.key_id
}
