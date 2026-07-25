variable "account_id" {
  description = "The vended account this baseline runs in — the calling root config carries a provider that has assumed OrganizationAccountAccessRole there (the one door a new account is born with)."
  type        = string
}

variable "network_tier" {
  description = "Optional network tier (small | medium | large). Omit (null) for no VPC — the correct state for Sandbox and service accounts. When declared, the CIDR comes from IPAM and the spoke attaches to the Cloud WAN core network; the account can't do this for itself, because Guardrails' IPAM-null deny means a VPC exists through the pipeline or not at all."
  type        = string
  default     = null

  validation {
    condition     = var.network_tier == null || contains(["small", "medium", "large"], coalesce(var.network_tier, "small"))
    error_message = "network_tier must be small, medium or large (or omitted)."
  }
}

variable "segment" {
  description = "The Cloud WAN segment the spoke joins, by attachment tag — derived from the account's OU (prod, nonprod, sandbox, infra)."
  type        = string
  default     = "nonprod"
}

variable "ipam_pool_id" {
  description = "The zone's IPAM pool — a range names its zone on sight."
  type        = string
  default     = null
}

variable "core_network_id" {
  description = "The Cloud WAN core network (live/network/)."
  type        = string
  default     = null
}

variable "logs_bucket_name" {
  description = "The Object-Locked sink in log-archive that this account's Config recorder delivers to — name-shaped, because leaves stay independently appliable."
  type        = string
  default     = "kestrel-org-cloudtrail-ap-southeast-2"
}

variable "logs_kms_key_arn" {
  description = "The SSE-KMS key the sink is encrypted with (alias ARN)."
  type        = string
  default     = "arn:aws:kms:ap-southeast-2:223456789012:alias/kestrel-org-logs"
}

variable "record_global_resource_types" {
  description = "Record global (IAM) resource types in this Region. True in ap-southeast-2 only — set in both Regions and every IAM record is paid for twice."
  type        = bool
  default     = true
}

variable "tags" {
  description = "The account's standard tags, stamped on everything the baseline creates."
  type        = map(string)
  # Defaulted so the module type-checks standalone; callers always pass
  # the account's real tags.
  default = {
    DataClassification = "OFFICIAL"
    Owner              = "platform-team@kestrel.com.au"
    CostCentre         = "CC-PLATFORM"
    Application        = "landing-zone"
  }
}
