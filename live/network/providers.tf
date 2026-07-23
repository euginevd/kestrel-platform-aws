# This leaf routes to the network account — the only network
# administrative boundary: workloads build VPCs and security groups but
# can't touch the core network policy or the path out.
#
# Both Regions run independently from the same code — Sydney first,
# Melbourne from the same modules behind the alias. Melbourne never
# reaches the internet through Sydney.

provider "aws" {
  region = "ap-southeast-2"
}

provider "aws" {
  alias  = "melbourne"
  region = "ap-southeast-4"
}
