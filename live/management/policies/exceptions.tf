# The register is Terraform-read (Guardrails decision 5) — an exception
# can't exist off-registry, and one that outlives its expiry becomes a
# finding, surfaced here as a failing plan-time check.

locals {
  exceptions = yamldecode(file("${path.module}/exceptions.yaml")).exceptions
}

check "exceptions_reconcile" {
  assert {
    condition = alltrue([
      for e in local.exceptions :
      alltrue([
        can(e.id),
        can(e.owner),
        can(e.reason),
        can(e.compensating_control),
        can(e.expiry),
      ])
    ])
    error_message = "Every exception must carry id, owner, reason, compensating control and expiry — an exception justified only in someone's memory is a hole with a good story."
  }

  assert {
    condition = alltrue([
      for e in local.exceptions :
      timecmp(plantimestamp(), "${e.expiry}T00:00:00Z") < 0
    ])
    error_message = "An exception has outlived its expiry — disposition it: renew with review, or remove the carve-out."
  }
}

output "exception_register" {
  description = "The reconciled register — read by the battery (exceptions row) and the assessment matrix."
  value       = { for e in local.exceptions : e.id => e.scope }
}
