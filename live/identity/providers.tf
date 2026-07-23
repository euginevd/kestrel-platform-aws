# This leaf routes to the identity account — the delegated administrator
# for IAM Identity Center (sso.amazonaws.com). Delegation moves
# administration, not the instance: the instance stays in the management
# account, and a delegated admin cannot alter permission sets provisioned
# there — PlatformAdmin stays management-managed, so this account can
# never grant access to the org root.

provider "aws" {
  region = "ap-southeast-2" # the Identity Center Region — permanent since Organisation step 9
}
