# Networking step 3 — IPAM, the address authority beside the fabric.
#
# IN `network`, NOT `shared-services` (Accounts decision 5): address
# allocation and routing are ONE administrative boundary. Whoever owns
# the routes owns the ranges, because an overlap is precisely the failure
# the fabric cannot route around after the fact.
#
# One allocator for both operating Regions; a pool per zone, so a range
# names its zone on sight and no two accounts overlap. IPAM ALLOCATES but
# does not enforce: a hand-carved CIDR still works until Guardrails' SCP
# denies ec2:CreateVpc without a pool (VpcsComeFromIpamOnly — the Null
# condition). That deny is that part's job; the gap is named here so it
# stays visible.

resource "aws_vpc_ipam" "this" {
  description = "Kestrel address authority — both operating Regions"

  operating_regions {
    region_name = local.regions.sydney
  }

  operating_regions {
    region_name = local.regions.melbourne
  }

  tags = local.standard_tags
}

resource "aws_vpc_ipam_pool" "zone" {
  for_each = local.zone_supernets

  description    = "Zone pool: ${each.key}"
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.this.private_default_scope_id

  # The estate is v4-only by position, not accident (Networking decision
  # 2) — the pools are carved so dual-stack is an ADDITION: a new pool at
  # the same hop, not a redesign.

  tags = merge(local.standard_tags, { Name = "zone-${each.key}" })
}

resource "aws_vpc_ipam_pool_cidr" "zone" {
  for_each = local.zone_supernets

  ipam_pool_id = aws_vpc_ipam_pool.zone[each.key].id
  cidr         = each.value
}

# Regional sub-pools per zone — allocations happen in-Region; the vending
# baseline asks the zone+Region pool for a tier-sized netmask.
resource "aws_vpc_ipam_pool" "zone_regional" {
  for_each = {
    for pair in setproduct(keys(local.zone_supernets), keys(local.regions)) :
    "${pair[0]}-${pair[1]}" => { zone = pair[0], region = local.regions[pair[1]] }
  }

  description         = "Zone pool: ${each.value.zone} (${each.value.region})"
  address_family      = "ipv4"
  ipam_scope_id       = aws_vpc_ipam.this.private_default_scope_id
  locale              = each.value.region
  source_ipam_pool_id = aws_vpc_ipam_pool.zone[each.value.zone].id

  tags = merge(local.standard_tags, { Name = "zone-${each.key}" })
}

resource "aws_vpc_ipam_pool_cidr" "zone_regional" {
  for_each = aws_vpc_ipam_pool.zone_regional

  ipam_pool_id = each.value.id
  # Each Region takes half its zone's supernet — Sydney the lower half,
  # Melbourne the upper (index by suffix).
  cidr = cidrsubnet(
    local.zone_supernets[split("-", each.key)[0]],
    1,
    endswith(each.key, "sydney") ? 0 : 1,
  )
}
