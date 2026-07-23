# This leaf routes to the security-tooling account — the delegated
# administrator for CloudTrail, Config, GuardDuty, Security Hub and
# Access Analyzer (live/management/organisation/delegation.tf).

provider "aws" {
  region = "ap-southeast-2"
}
