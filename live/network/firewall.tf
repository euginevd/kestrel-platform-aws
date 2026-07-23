# Networking step 6 — the rules, once per Region from the same module.

locals {
  allowed_domains = [
    ".kestrel.com.au",
    ".amazonaws.com",
    ".github.com",
  ]
}

module "firewall_rules_sydney" {
  source = "../../modules/firewall-rules"

  home_net_cidrs  = [for z, cidr in local.zone_supernets : cidr]
  allowed_domains = local.allowed_domains
  tags            = local.standard_tags
}

module "firewall_rules_melbourne" {
  source = "../../modules/firewall-rules"

  providers = {
    aws = aws.melbourne
  }

  home_net_cidrs  = [for z, cidr in local.zone_supernets : cidr]
  allowed_domains = local.allowed_domains
  tags            = local.standard_tags
}
