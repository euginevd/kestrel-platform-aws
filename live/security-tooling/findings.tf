# Logging & Monitoring step 8 — findings reach a person.
#
# WHAT PAGES, WHAT QUEUES AND WHAT IS ONLY A DASHBOARD is Kestrel's to
# specify, not left to the provider's defaults (Monitoring decision 5):
#
#   Page now  | break-glass or root use; Object Lock, trail or KMS-key
#             |   change; GuardDuty HIGH
#   Queue     | GuardDuty MED/LOW, CSPM control failures, Access
#             |   Analyzer external findings
#   Dashboard | Config drift, cost and volume trend — neither rule below
#             |   matches these, deliberately
#
# Note this is NOT a pure severity sort: root use and evidence-tampering
# page whatever severity they arrive with, because the thing that makes
# them urgent is what they are, not how they were scored. The
# tamper-attempt path itself is alarms.tf.
#
# The success criterion this serves is "every finding ends with a person,
# not a dashboard" — a finding that only ever lands in a console is one
# nobody agreed to look at.

resource "aws_sns_topic" "page" {
  name              = "kestrel-security-page"
  kms_master_key_id = aws_kms_key.findings.id

  tags = local.standard_tags
}

# The pager. Sample-finding-to-page is measured in the success criteria
# at five minutes.
resource "aws_cloudwatch_event_rule" "page" {
  name        = "kestrel-findings-page"
  description = "CRITICAL/HIGH findings, plus root use whatever its severity — page a human."

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Workflow    = { Status = ["NEW"] }
        RecordState = ["ACTIVE"]

        # Either severity is CRITICAL/HIGH, OR the finding is about root
        # credential use — which pages at any severity.
        "$or" = [
          { Severity = { Label = ["CRITICAL", "HIGH"] } },
          { Types = [{ prefix = "TTPs/PrivilegeEscalation" }] },
          { Title = [{ prefix = "Root credentials" }] },
        ]
      }
    }
  })

  tags = local.standard_tags
}

resource "aws_cloudwatch_event_target" "page" {
  rule      = aws_cloudwatch_event_rule.page.name
  target_id = "sns-page"
  arn       = aws_sns_topic.page.arn
}

# Everything below high queues as a case rather than waking anyone — the
# triage split is what stops the pager from being ignored.
resource "aws_cloudwatch_event_rule" "case" {
  name        = "kestrel-findings-case"
  description = "Security Hub findings below HIGH — open a case, do not page."

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity    = { Label = ["MEDIUM", "LOW", "INFORMATIONAL"] }
        Workflow    = { Status = ["NEW"] }
        RecordState = ["ACTIVE"]
      }
    }
  })

  tags = local.standard_tags
}

resource "aws_cloudwatch_event_target" "case" {
  rule      = aws_cloudwatch_event_rule.case.name
  target_id = "security-ir-case"
  arn       = "arn:aws:security-ir:ap-southeast-2:${data.aws_caller_identity.this.account_id}:case"
  role_arn  = aws_iam_role.findings_events.arn
}

data "aws_iam_policy_document" "findings_events_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "findings_events" {
  name               = "kestrel-findings-events"
  assume_role_policy = data.aws_iam_policy_document.findings_events_assume.json

  tags = local.standard_tags
}

data "aws_iam_policy_document" "sns_page" {
  statement {
    sid       = "AllowEventBridgePublish"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.page.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "cloudwatch.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "page" {
  arn    = aws_sns_topic.page.arn
  policy = data.aws_iam_policy_document.sns_page.json
}

# The topic is SSE-KMS, so the services that publish to it must be
# admitted by the KEY policy as well as the topic policy — otherwise the
# page is dropped at encryption time, which is the worst place to lose an
# alert.
data "aws_iam_policy_document" "findings_key" {
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
    sid       = "PublisherEncrypt"
    actions   = ["kms:GenerateDataKey*", "kms:Decrypt"]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",     # EventBridge — findings and tamper rules
        "cloudwatch.amazonaws.com", # the silence and delivery alarms
      ]
    }
  }
}

resource "aws_kms_key" "findings" {
  description             = "SSE-KMS for the finding notification path"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = data.aws_iam_policy_document.findings_key.json

  tags = local.standard_tags
}

resource "aws_kms_alias" "findings" {
  name          = "alias/kestrel-findings"
  target_key_id = aws_kms_key.findings.key_id
}
