variable "github_owner" {
  description = "GitHub organisation name (display form)."
  type        = string
  default     = "kestrel"
}

variable "github_owner_id" {
  description = "Immutable GitHub owner ID — enforced in sub claims since 15 Jul 2026; a renamed org cannot inherit the trust."
  type        = string
  default     = "1234567"
}

variable "github_repo" {
  description = "Repository name (display form)."
  type        = string
  default     = "kestrel-platform-aws"
}

variable "github_repo_id" {
  description = "Immutable GitHub repository ID."
  type        = string
  default     = "7654321"
}

variable "apply_environment" {
  description = "The GitHub environment the apply role is pinned to. Pin the ENVIRONMENT, not the branch — a branch can be recreated; the environment carries the protection rule."
  type        = string
  default     = "production"
}

variable "tags" {
  description = "The four standard tags."
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
