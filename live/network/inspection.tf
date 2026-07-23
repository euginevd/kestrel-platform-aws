# Networking steps 4–5 — the inspection VPCs, built once per Region
# behind a provider alias: Sydney first, Melbourne from the same code.
#
# Each Region runs its exit INDEPENDENTLY: the core network is global and
# segments span it, but service insertion attaches each Region's traffic
# to its own egress VPC — Melbourne never reaches the internet through
# Sydney, the no-hairpin rule expressed in policy rather than in the
# absence of a route. A separate east-west VPC means an internet-bound
# packet pays inspection once.

module "egress_sydney" {
  source = "../../modules/inspection-vpc"

  name                = "egress-sydney"
  cidr                = "10.64.0.0/22"
  core_network_id     = aws_networkmanager_core_network.this.id
  egress              = true
  firewall_policy_arn = module.firewall_rules_sydney.policy_arn
  tags                = local.standard_tags
}

module "east_west_sydney" {
  source = "../../modules/inspection-vpc"

  name                = "east-west-sydney"
  cidr                = "10.64.4.0/22"
  core_network_id     = aws_networkmanager_core_network.this.id
  egress              = false
  firewall_policy_arn = module.firewall_rules_sydney.policy_arn
  tags                = local.standard_tags
}

module "egress_melbourne" {
  source = "../../modules/inspection-vpc"

  providers = {
    aws = aws.melbourne
  }

  name                = "egress-melbourne"
  cidr                = "10.68.0.0/22"
  core_network_id     = aws_networkmanager_core_network.this.id
  egress              = true
  firewall_policy_arn = module.firewall_rules_melbourne.policy_arn
  tags                = local.standard_tags
}

module "east_west_melbourne" {
  source = "../../modules/inspection-vpc"

  providers = {
    aws = aws.melbourne
  }

  name                = "east-west-melbourne"
  cidr                = "10.68.4.0/22"
  core_network_id     = aws_networkmanager_core_network.this.id
  egress              = false
  firewall_policy_arn = module.firewall_rules_melbourne.policy_arn
  tags                = local.standard_tags
}

# Centralised interface endpoints (step 5), central DNS + DNS Firewall
# (step 8), CloudFront VPC origins (step 7), Firewall Manager delegation
# (step 12) and the hybrid edge (steps 10–11) layer onto this shape —
# each its own PR against this leaf.
