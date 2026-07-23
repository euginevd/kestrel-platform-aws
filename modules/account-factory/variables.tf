variable "name" {
  description = "Account name — also derives the root email (root+<name>@aws.kestrel.com.au). Root emails are never reusable, so a name that has ever been used is refused (see retired_names)."
  type        = string

  validation {
    condition     = can(regex("^kestrel-[a-z0-9-]+$", var.name))
    error_message = "Account names are kestrel-<slug>: lowercase, digits, hyphens."
  }
}

variable "ou_id" {
  description = "The resolved OU ID — the OU placement IS the whole governance story; guardrails and access assignments arrive by inheritance the moment the account lands."
  type        = string
}

variable "owner" {
  description = "Owner email — becomes the Owner tag."
  type        = string

  validation {
    condition     = can(regex("@kestrel.com.au$", var.owner))
    error_message = "Owner must be a kestrel.com.au address."
  }
}

variable "purpose" {
  description = "One line — carried as a tag for the walkable chain."
  type        = string
}

variable "request_ref" {
  description = "The ServiceNow ticket holding the business approval — stamped as a tag so the business record and the technical one are a single walkable chain from either end."
  type        = string

  validation {
    condition     = can(regex("^SNOW-REQ-[0-9]+$", var.request_ref))
    error_message = "request_ref must be a SNOW-REQ-<n> reference."
  }
}

variable "cost_centre" {
  description = "CostCentre tag value."
  type        = string
  default     = "CC-PLATFORM"
}

variable "data_classification" {
  description = "DataClassification tag value."
  type        = string
  default     = "OFFICIAL"

  validation {
    condition     = contains(["OFFICIAL", "OFFICIAL_Sensitive", "PROTECTED"], var.data_classification)
    error_message = "DataClassification must be one of the permitted set."
  }
}

variable "retired_names" {
  description = "Names that have ever been used — an email used for an account can never be used again, even after closure and termination, so the factory refuses them at plan time."
  type        = set(string)
  default     = []
}
