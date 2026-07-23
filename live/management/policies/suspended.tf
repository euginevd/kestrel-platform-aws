# Guardrails step 16 — Suspended reaches deny-all by DETACHING
# FullAWSAccess: absence over denial, so no future policy can
# accidentally override it (decision 4's one deliberate allow-list
# removal).
#
# The attachment was imported so it could be removed:
#
#   import {
#     to = aws_organizations_policy_attachment.suspended_full_access
#     id = "<Suspended OU id>:p-FullAWSAccess"
#   }
#
# That import block and its resource lived here for exactly one PR;
# removing them on the next apply detached the policy, leaving an
# implicit deny-all with no Allow for a future statement to be evaluated
# against. This file stays as the record — the git history of THIS PATH
# is the evidence trail for the detachment.
#
# Detach BEFORE any account moves in: AWS requires a node to keep one SCP
# during replacement, and an empty OU has nothing to lock out —
# quarantine is not the moment to debug an attachment.
