# Guardrails step 12 — the tag policy, backstopping the CI gate (CKV_KES_1),
# not replacing it. It enforces the VALUES of the four standard tags where
# set, and reports where they are not — by design, an untagged resource is
# still created and surfaces as non-compliant.

resource "aws_organizations_policy" "tags" {
  name        = "standard-tags"
  description = "Value enforcement for DataClassification; presence reporting for all four standard tags."
  type        = "TAG_POLICY"

  content = jsonencode({
    tags = {
      DataClassification = {
        tag_key = { "@@assign" = "DataClassification" }
        tag_value = {
          "@@assign" = [
            "OFFICIAL",
            "OFFICIAL_Sensitive",
            "PROTECTED",
          ]
        }
        enforced_for = {
          "@@assign" = ["s3:bucket", "ec2:instance", "ec2:volume", "secretsmanager:*"]
        }
      }
      Owner = {
        tag_key = { "@@assign" = "Owner" }
      }
      CostCentre = {
        tag_key = { "@@assign" = "CostCentre" }
      }
      Application = {
        tag_key = { "@@assign" = "Application" }
      }
    }
  })

  tags = local.standard_tags
}

resource "aws_organizations_policy_attachment" "tags" {
  policy_id = aws_organizations_policy.tags.id
  target_id = local.root_id
}
