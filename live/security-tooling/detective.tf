# Accounts steps 7–8 — GuardDuty, Security Hub CSPM and Access Analyzer,
# org-wide from the delegated admin, auto-enabled so no account joins
# unwatched.

# --- GuardDuty: all features, including Extended Threat Detection ------------

resource "aws_guardduty_detector" "this" {
  enable = true

  tags = local.standard_tags
}

resource "aws_guardduty_organization_configuration" "this" {
  detector_id                      = aws_guardduty_detector.this.id
  auto_enable_organization_members = "ALL" # existing accounts too, not just new
}

# All-features includes Extended Threat Detection (attack sequences) at no
# extra cost — it activates with the detector; the paid protection plans
# are enabled explicitly, org-wide:
resource "aws_guardduty_organization_configuration_feature" "all" {
  for_each = toset([
    "S3_DATA_EVENTS",
    "EKS_AUDIT_LOGS",
    "EBS_MALWARE_PROTECTION",
    "RDS_LOGIN_EVENTS",
    "LAMBDA_NETWORK_LOGS",
    "RUNTIME_MONITORING",
  ])

  detector_id = aws_guardduty_detector.this.id
  name        = each.key
  auto_enable = "ALL"
}

# --- Security Hub CSPM: one central configuration policy ---------------------

resource "aws_securityhub_organization_configuration" "this" {
  # MUST be false under central config — central config and per-account
  # auto-enable are mutually exclusive; the policy decides instead.
  auto_enable           = false
  auto_enable_standards = "NONE"

  organization_configuration {
    configuration_type = "CENTRAL"
  }
}

resource "aws_securityhub_configuration_policy" "baseline" {
  name        = "kestrel-baseline"
  description = "One central configuration policy from the delegated admin, inherited by every account joining later."

  configuration_policy {
    service_enabled = true

    enabled_standard_arns = [
      "arn:aws:securityhub:ap-southeast-2::standards/aws-foundational-security-best-practices/v/1.0.0",
    ]

    security_controls_configuration {
      disabled_control_identifiers = []
    }
  }

  depends_on = [aws_securityhub_organization_configuration.this]
}

resource "aws_securityhub_configuration_policy_association" "root" {
  # Associated at the ORG ROOT — every account, existing and future,
  # inherits the same policy with zero per-account work.
  target_id = "r-kest0"
  policy_id = aws_securityhub_configuration_policy.baseline.id
}

# --- IAM Access Analyzer: the org as its zone of trust -----------------------

resource "aws_accessanalyzer_analyzer" "org" {
  analyzer_name = "kestrel-org"
  type          = "ORGANIZATION"

  tags = local.standard_tags
}

# Findings land in the aggregator and stop — routing them to a human
# (severity, paging, triage) waits for real finding volume to tune
# against; timely analysis (ISM-1906/1907) is the Response part's
# obligation, not this one's. Logs are never filtered; noise reduction
# happens in the finding pipeline, never in the evidence one.
