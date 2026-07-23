# The network tier — the one big thing in the box, and only if declared.
#
# The factory allocates the CIDR from the zone's IPAM pool, builds the
# spoke — private subnets, no IGW, standard endpoints via the centralised
# set — and attaches it to the Cloud WAN core network, joining its
# segment by tag, so the account's first packet already crosses the
# inspected exit. An account that declares no tier has no network — the
# correct state for Sandbox and service accounts, and the account can't
# build its own: Guardrails' IPAM-null deny means a VPC exists through
# the pipeline or not at all.

locals {
  tier_netmask = {
    small  = 24
    medium = 22
    large  = 20
  }
}

module "network" {
  source = "./network"

  count = var.network_tier != null ? 1 : 0

  ipam_pool_id    = var.ipam_pool_id
  netmask_length  = local.tier_netmask[var.network_tier]
  segment         = var.segment
  core_network_id = var.core_network_id
  tags            = var.tags
}
