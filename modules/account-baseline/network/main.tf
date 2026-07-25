# The spoke itself — a child module so it exists only when a tier is
# declared (the parent gates the call), and every resource here is
# unconditional.

data "aws_availability_zones" "this" {
  state = "available"
}

resource "aws_vpc" "this" {
  # The CIDR is IPAM-allocated — a hand-carved CIDR is exactly what
  # Guardrails' VpcsComeFromIpamOnly deny refuses.
  ipv4_ipam_pool_id   = var.ipam_pool_id
  ipv4_netmask_length = var.netmask_length

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "spoke" })
}

resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.this.id
  availability_zone = data.aws_availability_zones.this.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 2, count.index)

  # Private on purpose: no IGW exists in this VPC to route to, no public
  # IPs can be assigned (the NoPublicAddresses deny), and the way out is
  # the core network attachment below.
  map_public_ip_on_launch = false

  tags = merge(var.tags, { Name = "private-${count.index}" })
}

resource "aws_default_security_group" "this" {
  # The default SG restricts ALL traffic — no rules; workloads define
  # their own groups referencing groups, never CIDRs (Networking
  # decision 5).
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "default-locked" })
}

# Logging & Monitoring step 4 — flow and DNS query logs ship INSIDE this
# module, so there is no account-level toggle to forget or turn off. The
# coverage query enumerates VPCs from Resource Explorer and asks which
# are logging; a VPC built through this module always answers yes.

resource "aws_flow_log" "this" {
  vpc_id = aws_vpc.this.id

  traffic_type         = "ALL" # accepted AND rejected — a reject is the interesting one
  log_destination_type = "s3"
  log_destination      = "${var.logs_bucket_arn}/vpc-flow-logs/"

  destination_options {
    file_format        = "parquet" # Athena scans less of it, which is the spend cap's friend
    per_hour_partition = true
  }

  tags = merge(var.tags, { Name = "spoke-flow-logs" })
}

# DNS is where exfiltration hides in an estate with no IGW — the query is
# often the only trace of a destination the packet never reached.
resource "aws_route53_resolver_query_log_config" "this" {
  name            = "spoke-dns-queries"
  destination_arn = "${var.logs_bucket_arn}/resolver-query-logs/"

  tags = merge(var.tags, { Name = "spoke-dns-queries" })
}

resource "aws_route53_resolver_query_log_config_association" "this" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.this.id
  resource_id                  = aws_vpc.this.id
}

resource "aws_networkmanager_vpc_attachment" "this" {
  core_network_id = var.core_network_id
  vpc_arn         = aws_vpc.this.arn
  subnet_arns     = aws_subnet.private[*].arn

  tags = merge(var.tags, {
    # The attachment joins its segment BY TAG — the core network policy's
    # attachment-policy rules read it and place the spoke; nothing here
    # holds a route of its own.
    segment = var.segment
  })
}
