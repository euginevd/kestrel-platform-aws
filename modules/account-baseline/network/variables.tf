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

variable "logs_bucket_arn" {
  description = "The Object-Locked sink in log-archive that flow and DNS query logs deliver to — Monitoring step 4 puts them in this module so no account can toggle them off."
  type        = string
  default     = "arn:aws:s3:::kestrel-org-cloudtrail-ap-southeast-2"
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
