# Guardrails step 14 — VPC Block Public Access, bidirectional. The
# data-plane half of the network claim, and the instrument decision 1
# prefers: it blocks internet-gateway traffic regardless of route tables,
# security groups or which API created what.
#
# This is the one policy whose breakage is INVISIBLE in CloudTrail — a
# blocked packet raises no API denial, so the symptom is a workload that
# can't reach the internet with no log line explaining why.
#
# It attaches to Workloads, NOT the root, because the genuinely
# internet-routed egress VPC lives in `network` under Infrastructure,
# outside this attachment.

resource "aws_organizations_policy" "vpc_bpa" {
  name        = "vpc-bpa"
  description = "Internet-gateway traffic dropped at the network layer for every Workloads VPC; the egress VPC is excluded by living outside the attachment, and any in-zone exclusion is by VPC ID, not tag."
  type        = "DECLARATIVE_POLICY_EC2"

  content = jsonencode({
    ec2_attributes = {
      vpc_block_public_access = {
        internet_gateway_block = {
          mode               = { "@@assign" = "block-bidirectional" }
          exclusions_allowed = { "@@assign" = "enabled" } # egress VPC excluded by ID, not tag
        }
      }
    }
  })

  tags = local.standard_tags
}

resource "aws_organizations_policy_attachment" "vpc_bpa" {
  policy_id = aws_organizations_policy.vpc_bpa.id
  target_id = local.top_ou_ids["Workloads"]
}
