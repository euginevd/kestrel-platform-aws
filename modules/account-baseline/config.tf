# Logging & Monitoring step 3 — the Config recorder, per account.
#
# The recorder and delivery channel are per-account-per-Region resources;
# the org-wide aggregator lives in live/security-tooling/config.tf. Both
# deliver to the same sink in log-archive.
#
# PER REGION means this module is instantiated once per operating Region
# with a provider aliased to each, and ONLY the ap-southeast-2 call
# passes record_global_resource_types = true. Set it in both and every
# IAM configuration item is recorded — and billed — twice, which is a
# cost bug that looks exactly like working coverage.
#
# TWO SPEEDS, chosen per resource type (Monitoring decision 3): Config
# pricing punishes churn on high-turnover resources, and a daily snapshot
# of an autoscaling group still answers the assessor's "what did it look
# like on the 14th?" at a fraction of the cost. Identity, network and
# security-relevant types stay CONTINUOUS — for those, a change between
# snapshots is the change that matters.
#
# Moving a type from daily to continuous is one line of this list.

locals {
  # Continuous: anything where the state BETWEEN two daily snapshots is
  # itself the evidence — who could reach what, and what was exposed.
  continuous_types = [
    "AWS::IAM::Role",
    "AWS::IAM::Policy",
    "AWS::IAM::User",
    "AWS::IAM::Group",
    "AWS::KMS::Key",
    "AWS::EC2::SecurityGroup",
    "AWS::EC2::NetworkAcl",
    "AWS::EC2::VPC",
    "AWS::EC2::Subnet",
    "AWS::EC2::RouteTable",
    "AWS::S3::Bucket",
    "AWS::CloudTrail::Trail",
    "AWS::Config::ResourceCompliance",
  ]
}

data "aws_iam_policy_document" "config_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config" {
  name               = "kestrel-config-recorder"
  assume_role_policy = data.aws_iam_policy_document.config_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  name     = "kestrel-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true

    # Global (IAM) resource types are recorded in ap-southeast-2 ONLY —
    # set in both Regions and every IAM record is paid for twice.
    include_global_resource_types = var.record_global_resource_types
  }

  recording_mode {
    recording_frequency = "DAILY"

    recording_mode_override {
      description         = "Identity, network and security types where a between-snapshots change is the evidence."
      resource_types      = local.continuous_types
      recording_frequency = "CONTINUOUS"
    }
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "kestrel-delivery"
  s3_bucket_name = var.logs_bucket_name
  s3_kms_key_arn = var.logs_kms_key_arn

  # The recorder must exist before the channel it delivers through.
  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}
