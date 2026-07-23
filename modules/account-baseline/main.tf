# The birth baseline — Vending decision 3: in-account steps ONLY where no
# OU-attached control can reach. Everything already carried by SCPs,
# RCPs, declarative policies, assignments or org-level enrolment is
# deliberately NOT repeated — a baseline that duplicates inherited
# governance is a second copy that drifts.
#
# Every step is IDEMPOTENT — a failed vend is finished by re-running the
# apply, never by hand, and the battery is what proves done: an account
# is vended when it passes, not when the pipeline went green once.
#
# Order matters once: KestrelDeploy first, because every later step and
# every future apply arrives through it, not through the birth role.
# This same baseline is the brownfield graduation checklist — one path,
# not two.

# 1. The deploy role — via the same module the bootstrap accounts use.
module "oidc" {
  source = "../github-oidc"

  tags = var.tags
}

# 2. Melbourne opt-in — per-account, closing the item Organisation parked:
#    a human stamped it there, the factory stamps it thereafter. The
#    active-active posture (ADR-0005) is fiction in this account until
#    it's on.
resource "aws_account_region" "melbourne" {
  region_name = "ap-southeast-4"
  enabled     = true
}

# 3. Default VPCs deleted in both Regions. Terraform cannot delete a
#    default VPC declaratively; the factory runs the deletion as an
#    idempotent in-pipeline step (delete-default-vpcs), and this
#    posture setting stops a new one appearing without a deliberate act.
#    A workload account's network is the declared tier (network.tf) or
#    nothing.

# 4. Alternate contacts — the same three monitored DLs as every account.
resource "aws_account_alternate_contact" "this" {
  for_each = {
    BILLING    = { email = "aws-billing@kestrel.com.au", name = "Kestrel Billing", phone = "+61-2-5550-0000", title = "Billing (DL)" }
    OPERATIONS = { email = "aws-operations@kestrel.com.au", name = "Kestrel Operations", phone = "+61-2-5550-0001", title = "Operations (DL)" }
    SECURITY   = { email = "aws-security@kestrel.com.au", name = "Kestrel Security", phone = "+61-2-5550-0002", title = "Security (DL)" }
  }

  alternate_contact_type = each.key
  email_address          = each.value.email
  name                   = each.value.name
  phone_number           = each.value.phone
  title                  = each.value.title
}
