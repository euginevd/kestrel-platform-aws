variable "ipam_pool_id" {
  type = string
}

variable "netmask_length" {
  type = number
}

variable "segment" {
  type = string
}

variable "core_network_id" {
  type = string
}

variable "tags" {
  type = map(string)
  # Defaulted so the module type-checks standalone; callers always pass
  # the account's real tags.
  default = {
    DataClassification = "OFFICIAL"
    Owner              = "platform-team@kestrel.com.au"
    CostCentre         = "CC-PLATFORM"
    Application        = "landing-zone"
  }
}
