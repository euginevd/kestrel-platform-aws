# Identity step 1 — four coarse sets, not fourteen (decision 1: RBAC,
# ABAC deferred behind a stated flip condition — assignments exceed ~200,
# or one team needs per-account differentiation across more than ~10
# accounts).
#
# Durations by decision 2: the session duration is the second half of the
# de-elevation overhang, so it is the half we control — privileged sets
# get 1 hour, read-only 4.
#
# WorkloadDeploy is PowerUserAccess — acceptable while workloads are
# internal, replaced with a per-workload scoped policy the moment an
# agency-facing workload lands in Prod.
#
# SecurityRead → SecurityAudit was create-then-move-then-destroy across
# two applies, never a rename — a permission set's name is its identity.

locals {
  permission_sets = {
    PlatformAdmin = {
      duration = "PT1H" # ISO-8601, not "4h"
      managed  = "arn:aws:iam::aws:policy/AdministratorAccess"
    }
    WorkloadDeploy = {
      duration = "PT1H"
      managed  = "arn:aws:iam::aws:policy/PowerUserAccess"
    }
    PlatformReadOnly = {
      duration = "PT4H"
      managed  = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    }
    SecurityAudit = {
      duration = "PT4H"
      managed  = "arn:aws:iam::aws:policy/SecurityAudit"
    }
  }
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = local.permission_sets

  instance_arn     = local.sso_instance_arn
  name             = each.key
  session_duration = each.value.duration

  tags = local.standard_tags
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = local.permission_sets

  instance_arn       = local.sso_instance_arn
  managed_policy_arn = each.value.managed
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
}
