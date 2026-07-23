terraform {
  backend "s3" {
    bucket       = "kes-shared-syd-tfstate"
    key          = "live/management/policies/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
