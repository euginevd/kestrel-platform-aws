# The Region's firewall rules — Networking step 6. Instantiated once per
# Region (Network Firewall is Regional); both Regions carry the same
# rules from the same code.
#
# Rules are Terraform, reviewed by PR, governed estate-wide by Firewall
# Manager. New rules land on ALERT first, move to drop only after the
# logs are read — a false positive is a log line, not an outage.
#
# Two traps that fail silently: rule order must be STRICT (Suricata's
# action-order default is an IDS habit), and $HOME_NET must not swallow
# every estate CIDR or the managed rules quietly stop matching.

data "aws_caller_identity" "this" {}

# The account-root admin statement is the standard KMS pattern; inside a
# KEY policy, Resource "*" scopes to the key itself.
data "aws_iam_policy_document" "key" {
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

resource "aws_networkfirewall_rule_group" "egress_allowlist" {
  name     = "kestrel-egress-allowlist"
  capacity = 300 # provisioned at 2–3× current rule count — fixed at creation
  type     = "STATEFUL"

  encryption_configuration {
    type   = "CUSTOMER_KMS"
    key_id = aws_kms_key.policy.arn
  }

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"

        ip_set {
          # The zone supernets — deliberately scoped, not 0.0.0.0/0.
          definition = var.home_net_cidrs
        }
      }
    }

    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["TLS_SNI", "HTTP_HOST"]
        # Domain filtering reads the Host header and TLS SNI —
        # client-supplied, so SPOOFABLE; that limit is what the
        # TLS-inspection register exists for (decision 6).
        targets = var.allowed_domains
      }
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = var.tags
}

resource "aws_kms_key" "policy" {
  description             = "CMK for the Network Firewall policy and rule groups"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.key.json

  tags = var.tags
}

resource "aws_networkfirewall_firewall_policy" "this" {
  name = "kestrel-inspection"

  encryption_configuration {
    type   = "CUSTOMER_KMS"
    key_id = aws_kms_key.policy.arn
  }

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    # Alert-before-drop: anything established that no rule matched
    # alerts; the drop flip is a later PR with the log to justify it.
    stateful_default_actions = ["aws:alert_established"]

    stateful_rule_group_reference {
      priority     = 100
      resource_arn = aws_networkfirewall_rule_group.egress_allowlist.arn
    }
  }

  tags = var.tags
}
