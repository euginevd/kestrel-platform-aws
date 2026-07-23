# Accounts step 6 — Config, aggregated here.
#
# The recorder + delivery channel run PER ACCOUNT per Region from the
# factory's account baseline (live/management/accounts/), all delivering
# to log-archive; this leaf holds the org-wide aggregator. The ordering
# is forced, not preferred: Config must be recording BEFORE Security Hub
# CSPM enables (detective.tf), or CSPM's controls silently evaluate
# nothing — the worst failure mode a detective control has.

data "aws_iam_policy_document" "config_aggregator_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config_aggregator" {
  name               = "kestrel-config-aggregator"
  assume_role_policy = data.aws_iam_policy_document.config_aggregator_assume.json

  tags = local.standard_tags
}

resource "aws_iam_role_policy_attachment" "config_aggregator" {
  role       = aws_iam_role.config_aggregator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_configuration_aggregator" "org" {
  name = "kestrel-org"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_aggregator.arn
  }

  tags = local.standard_tags
}
