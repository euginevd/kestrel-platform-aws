locals {
  standard_tags = {
    DataClassification = "OFFICIAL"
    Owner              = "platform-team@kestrel.com.au"
    CostCentre         = "CC-PLATFORM"
    Application        = "landing-zone"
  }

  regions = {
    sydney    = "ap-southeast-2"
    melbourne = "ap-southeast-4"
  }

  # A pool per zone — a range names its zone on sight and no two accounts
  # overlap, the one failure the fabric can't route around later.
  zone_supernets = {
    prod    = "10.32.0.0/12"
    nonprod = "10.48.0.0/12"
    infra   = "10.64.0.0/13"
    sandbox = "10.72.0.0/14"
  }
}
