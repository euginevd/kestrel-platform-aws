# One inspection VPC — Networking step 4. Instantiated four times: egress
# and east-west, in each Region, from the same code.
#
# Keep NOTHING but the firewall in the firewall subnets — Network
# Firewall can't inspect traffic in its own subnet.

data "aws_availability_zones" "this" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.this.names, 0, 3)
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "inspection-${var.name}" })
}

resource "aws_subnet" "firewall" {
  count = 3

  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.cidr, 4, count.index)

  tags = merge(var.tags, { Name = "firewall-${count.index}" })
}

resource "aws_subnet" "public" {
  count = var.egress ? 3 : 0

  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.cidr, 4, count.index + 8)

  # Public by ROLE, not by auto-assignment — the NAT gateways live here.
  map_public_ip_on_launch = false

  tags = merge(var.tags, { Name = "public-${count.index}" })
}

# --- The estate's only way out (egress role only) ----------------------------

resource "aws_internet_gateway" "this" {
  count = var.egress ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "egress" })
}

resource "aws_eip" "nat" {
  count = var.egress ? 3 : 0

  domain = "vpc"

  tags = merge(var.tags, { Name = "nat-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  # One per AZ — egress survives the loss of an AZ (success criterion 1).
  count = var.egress ? 3 : 0

  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id

  tags = merge(var.tags, { Name = "nat-${count.index}" })

  depends_on = [aws_internet_gateway.this]
}

# --- The firewall ------------------------------------------------------------

data "aws_caller_identity" "this" {}

data "aws_iam_policy_document" "firewall_key" {
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

resource "aws_kms_key" "firewall" {
  description             = "CMK for Network Firewall state (${var.name})"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.firewall_key.json

  tags = var.tags
}

resource "aws_networkfirewall_firewall" "this" {
  name                = "kestrel-${var.name}"
  vpc_id              = aws_vpc.this.id
  firewall_policy_arn = var.firewall_policy_arn

  delete_protection                 = true
  firewall_policy_change_protection = false
  subnet_change_protection          = true

  encryption_configuration {
    type   = "CUSTOMER_KMS"
    key_id = aws_kms_key.firewall.arn
  }

  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall

    content {
      subnet_id = subnet_mapping.value.id
    }
  }

  tags = var.tags
}

# --- The attachment that does the steering -----------------------------------

resource "aws_networkmanager_vpc_attachment" "this" {
  core_network_id = var.core_network_id
  vpc_arn         = aws_vpc.this.arn
  subnet_arns     = aws_subnet.firewall[*].arn

  options {
    # Appliance mode must be on the INSPECTION VPC attachment, or a
    # request and its reply land on different AZ endpoints and get
    # dropped. It works only because spokes attach to a SEGMENT — static
    # routes carry no AZ metadata, so the mode has nothing to key on
    # without them (AWS docs, read Jul 2026).
    appliance_mode_support = true
  }

  tags = merge(var.tags, {
    nfg = "inspection" # joins the NFG by tag
  })
}

resource "aws_default_security_group" "this" {
  # The default SG restricts ALL traffic — no rules; anything real gets
  # its own group referencing groups, never CIDRs.
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "default-locked" })
}
