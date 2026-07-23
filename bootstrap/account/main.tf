# Step 5 — vend kestrel-shared-services by hand, on THROWAWAY LOCAL STATE,
# deliberately: the one account the factory can't vend, because the factory
# needs the backend and the backend needs this account.
#
# This root config's local state is abandoned after the account exists —
# the account is later adopted by the factory via `import`, never rebuilt,
# so it keeps its identity while the code that owns it changes hands.
# (The factory's adoption entry lives in live/management/accounts/.)

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
  # The operator's Identity Center session — management account.
}

resource "aws_organizations_account" "shared_services" {
  name  = "kestrel-shared-services"
  email = "root+shared-services@aws.kestrel.com.au" # the Organisation scheme (ADR-0001)

  # No parent_id: the OU tree doesn't exist yet — the account lands at the
  # org root and moves under Infrastructure when Accounts builds the tree.

  # Centralised root access management is on (Organisation step 4), so this
  # account is born without root credentials.

  tags = merge(
    {
      DataClassification = "OFFICIAL"
      Owner              = "platform-team@kestrel.com.au"
      CostCentre         = "CC-PLATFORM"
      Application        = "landing-zone"
    },
    { Name = "kestrel-shared-services" }
  )

  lifecycle {
    prevent_destroy = true # never create — or close — a live account by accident
  }
}

output "account_id" {
  description = "Feed this to bootstrap/main.tf (step 7) and accounts.json."
  value       = aws_organizations_account.shared_services.id
}
