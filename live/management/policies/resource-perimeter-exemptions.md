# Resource-perimeter exemptions

The outbound list is longer than the inbound one — engineers add vendor
buckets and package repositories without recording them — so the
resource-perimeter SCP needed its own CloudTrail discovery pass over every
non-org `aws:ResourceOrgID` before it attached. These are the exemptions
that pass produced, each with its reason, because an exemption justified
only in someone's memory is a hole with a good story.

The SCP expresses exemptions structurally (the `aws-service-role/*`
principal carve-out); anything listed here and not yet in the policy is a
pending change with an owner, not an informal allowance.

| Path | Why it crosses the perimeter | Mechanism | Owner |
|------|------------------------------|-----------|-------|
| AWS log delivery (`delivery.logs.amazonaws.com` writes) | Service-side delivery to AWS-owned staging before landing in our sink | Service-linked role carve-out in the SCP | security-team |
| Service-linked roles (`aws-service-role/*`) | AWS services acting on our behalf against AWS-owned resources | `ArnNotLike` carve-out in the SCP | security-team |
| Public package repositories (via the egress proxy) | Build-time dependencies; the estate never pulls third-party code at apply time, but workload builds fetch from public registries | Traffic egresses through the inspected exit; the perimeter governs AWS API access, not HTTPS to registries | platform-team |

Read alongside `exceptions.yaml` — that register carries owner/expiry
discipline for policy carve-outs; this file records why each *structural*
exemption in `resource-perimeter.json` exists.
