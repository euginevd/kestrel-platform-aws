# Networking steps 1–2 — the policy document IS the fabric.
#
# Segments, isolation and where traffic is inspected are all declared
# here, in ONE VERSIONED DOCUMENT: an edit is a new policy version,
# reviewed and applied as a whole, so a segmentation change is a diff a
# reviewer reads rather than a set of tables kept coherent by hand.

resource "aws_networkmanager_global_network" "this" {
  description = "Kestrel global network"

  tags = local.standard_tags
}

data "aws_networkmanager_core_network_policy_document" "this" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["64512-64555"]

    edge_locations {
      location = local.regions.sydney
    }

    edge_locations {
      location = local.regions.melbourne
    }
  }

  # A segment per zone. isolate_attachments = true is what makes a segment
  # a boundary — without it, two VPCs in the same segment reach each other
  # directly and service insertion is bypassed. It is also REQUIRED for
  # same-segment inspection to work at all.
  segments {
    name                          = "prod"
    require_attachment_acceptance = false
    isolate_attachments           = true
  }

  segments {
    name                          = "nonprod"
    require_attachment_acceptance = false
    isolate_attachments           = true
  }

  segments {
    name                          = "sandbox"
    require_attachment_acceptance = false
    isolate_attachments           = true
  }

  segments {
    name                          = "infra"
    require_attachment_acceptance = false
    isolate_attachments           = true
  }

  # One NFG per inspection role, joined by attachment tag.
  network_function_groups {
    name                          = "inspection"
    require_attachment_acceptance = false
  }

  # send-via steers east-west BETWEEN segments through the east-west
  # inspection VPC; dual-hop requires an inspection attachment in BOTH
  # Regions — the mode that keeps cross-Region east-west inspected on
  # both edges.
  segment_actions {
    action  = "send-via"
    segment = "prod"
    mode    = "dual-hop"

    when_sent_to {
      segments = ["nonprod"]
    }

    via {
      network_function_groups = ["inspection"]
    }
  }

  # send-to steers each segment's EGRESS to the egress VPC. A 0.0.0.0/0
  # showing blackholed on a send-to segment is EXPECTED, not a fault
  # (AWS docs, read Jul 2026).
  segment_actions {
    action  = "send-to"
    segment = "prod"

    via {
      network_function_groups = ["inspection"]
    }
  }

  segment_actions {
    action  = "send-to"
    segment = "nonprod"

    via {
      network_function_groups = ["inspection"]
    }
  }

  segment_actions {
    action  = "send-to"
    segment = "sandbox"

    via {
      network_function_groups = ["inspection"]
    }
  }

  # Attachments join their segment (or NFG) BY TAG — the factory's spoke
  # attachment carries segment=<zone>; the inspection VPCs carry
  # nfg=inspection.
  attachment_policies {
    rule_number     = 100
    condition_logic = "or"

    conditions {
      type  = "tag-value"
      key   = "nfg"
      value = "inspection"
    }

    action {
      add_to_network_function_group = "inspection"
    }
  }

  attachment_policies {
    rule_number     = 200
    condition_logic = "or"

    conditions {
      type = "tag-exists"
      key  = "segment"
    }

    action {
      association_method = "tag"
      tag_value_of_key   = "segment"
    }
  }
}

resource "aws_networkmanager_core_network" "this" {
  global_network_id = aws_networkmanager_global_network.this.id
  description       = "Kestrel core network — segments as policy"

  tags = local.standard_tags
}

resource "aws_networkmanager_core_network_policy_attachment" "this" {
  core_network_id = aws_networkmanager_core_network.this.id
  policy_document = data.aws_networkmanager_core_network_policy_document.this.json
}
