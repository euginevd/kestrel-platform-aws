variable "home_net_cidrs" {
  description = "What $HOME_NET means in this Region — the zone supernets, never every estate CIDR."
  type        = list(string)
}

variable "allowed_domains" {
  description = "The egress allow-list — TLS SNI / HTTP Host targets."
  type        = list(string)
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
