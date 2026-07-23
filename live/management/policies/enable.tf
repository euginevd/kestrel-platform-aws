# Guardrails step 4 — types before policies.
#
# RESOURCE_CONTROL_POLICY and DECLARATIVE_POLICY_EC2 must be enabled at
# the organisation before any policy of that type can exist. The
# organisation is ONE resource and its home is
# live/management/organisation/main.tf — the Guardrails PR added the two
# new types to `enabled_policy_types` there; this file records the call
# where the page places it, so the sequencing is findable from either
# leaf.
#
# Both types arrive with an AWS-managed full-access policy. Leave
# RCPFullAWSAccess attached at the root: detaching a managed full-access
# policy is the Suspended deny-all pattern (suspended.tf) — doing it at
# the root denies the whole organisation at once.
