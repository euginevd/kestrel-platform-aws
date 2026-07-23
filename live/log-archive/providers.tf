# This leaf routes to the log-archive account (accounts.json: log-archive)
# — the account NOBODY logs into. Its only human-shaped principal is the
# pipeline's own pair of roles.

provider "aws" {
  region = "ap-southeast-2"
}

provider "aws" {
  alias  = "melbourne"
  region = "ap-southeast-4"
}
