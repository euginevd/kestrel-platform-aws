variable "name" {
  description = "egress or east-west, per Region."
  type        = string
}

variable "cidr" {
  description = "The inspection VPC's CIDR — from the infra zone's plan, not a workload pool."
  type        = string
}

variable "core_network_id" {
  description = "The Cloud WAN core network this VPC attaches to."
  type        = string
}

variable "egress" {
  description = "true builds the egress role: NAT and the estate's only outbound internet gateway live here. false is the east-west inspection role — firewall only."
  type        = bool
  default     = false
}

variable "firewall_policy_arn" {
  description = "The Network Firewall policy (rules are Terraform, reviewed by PR, governed estate-wide by Firewall Manager)."
  type        = string
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
