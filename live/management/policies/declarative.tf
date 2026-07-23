# Guardrails step 11 — configuration set as fact. No API to catch; a
# non-compliant instance can't be launched, so there is no enumeration to
# get wrong (decision 1's order of preference).

resource "aws_organizations_policy" "declarative_ec2" {
  name        = "ec2-baseline"
  description = "IMDSv2 required, allowed-images enforcement on, public snapshot sharing blocked."
  type        = "DECLARATIVE_POLICY_EC2"

  content = jsonencode({
    ec2_attributes = {
      instance_metadata_defaults = {
        http_tokens = { "@@assign" = "required" } # IMDSv2
      }
      allowed_images_settings = {
        state = { "@@assign" = "enabled" }
      }
      snapshot_block_public_access = {
        state = { "@@assign" = "block-all-sharing" }
      }
    }
  })

  tags = local.standard_tags
}

resource "aws_organizations_policy_attachment" "declarative_ec2" {
  policy_id = aws_organizations_policy.declarative_ec2.id
  target_id = local.root_id
}
