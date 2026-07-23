# Identical in every root config — the toolchain pin is estate-wide.
# The committed .terraform.lock.hcl is what makes the provider build
# reproducible; the pipeline verifies it with `terraform init -lockfile=readonly`.
# The >= 1.10 floor is what enables native S3 state locking (use_lockfile)
# and drops the DynamoDB table.

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
