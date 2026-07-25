# Accounts step 5 + Logging & Monitoring step 5 — the four watchers and
# the plane they land in, org-wide from the delegated admin, auto-enabled
# so no account joins unwatched.
#
# GuardDuty for threats, Inspector for vulnerabilities, Macie for where
# the PROTECTED data actually is, Access Analyzer for what's reachable —
# all landing in Security Hub as the single prioritisation plane
# (Monitoring decision 4).
#
# Detective is DECLINED, not overlooked: investigation happens in the
# provider's Sentinel (securitylake.tf), and paying twice for correlation
# is a decision. Flip: the SOC contract ending, at which point Detective
# becomes the interim investigation surface.

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

# --- Inspector: continuous vulnerability scanning ----------------------------

# Inventory-driven, not scheduled — EC2, container images and Lambda are
# scanned as they appear, which is the only model that survives an estate
# that vends accounts.
#
# Detection only counts if remediation has a clock (Monitoring decision
# 4): critical patched within TWO WEEKS of vendor release, or 48 HOURS
# where an exploit is in the wild — the Essential Eight cadence. It is
# tracked as an exposure score falling rather than a ticket closing, and
# an unmet window becomes a Guardrails exception with an owner and an
# expiry (live/management/policies/exceptions.yaml).
resource "aws_inspector2_organization_configuration" "this" {
  auto_enable {
    ec2         = true
    ecr         = true
    lambda      = true
    lambda_code = true
  }
}

# --- Macie: where the PROTECTED data actually is -----------------------------

resource "aws_macie2_account" "this" {
  status                       = "ENABLED"
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# For a PROTECTED estate this answers the question a data-classification
# policy only asserts — sampling and classifying objects rather than
# trusting the tag someone applied.
resource "aws_macie2_organization_configuration" "this" {
  auto_enable = true

  depends_on = [aws_macie2_account.this]
}

# --- Security Hub: two layers, not two products ------------------------------
#
# The December 2025 Security Hub is the PLANE — it correlates GuardDuty,
# Inspector, Macie and CSPM signals into exposure findings with a risk
# score and attack path, so prioritisation stops being a severity sort.
# CSPM is the LAYER UNDERNEATH, still the normalised feed of standards
# and control results. Enabling the plane does not retire CSPM; the
# central configuration policy below is what CSPM runs on.

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

# Routing findings to a human is findings.tf — EventBridge by severity,
# per Monitoring step 8. The split holds either way: findings are for
# humans and get tuned, but the logs feeding log-archive are for
# assessors and are NEVER filtered. Noise reduction happens in the
# finding pipeline, never in the evidence one.
