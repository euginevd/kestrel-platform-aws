# How the bootstrap session authenticates — steps 5–10 run from one laptop
# session on short-lived Identity Center credentials (PlatformAdmin in the
# management account). No access keys are created at any point; the
# shared-services account is reached by assuming the role every vended
# account is born with.

provider "aws" {
  region = "ap-southeast-2"
  # Credentials: the operator's Identity Center session — management account.
}

provider "aws" {
  alias  = "shared_services"
  region = "ap-southeast-2"

  assume_role {
    # The one door a new account is born with (Bootstrap step 6) — the hop
    # is attributed to the operator's Identity Center session in CloudTrail.
    role_arn = "arn:aws:iam::423456789012:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias  = "shared_services_melbourne"
  region = "ap-southeast-4"

  assume_role {
    role_arn = "arn:aws:iam::423456789012:role/OrganizationAccountAccessRole"
  }
}
