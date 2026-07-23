# One directory = one state object (Bootstrap decision 3) — a guardrail
# change can't take the network down, applies stay fast, no shared lock.

terraform {
  backend "s3" {
    bucket       = "kes-shared-syd-tfstate"
    key          = "live/management/organisation/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
