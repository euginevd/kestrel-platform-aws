terraform {
  backend "s3" {
    bucket       = "kes-shared-syd-tfstate"
    key          = "live/network/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
