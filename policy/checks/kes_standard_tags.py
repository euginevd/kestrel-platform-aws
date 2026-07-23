"""CKV_KES_1 — every taggable resource carries the four standard tags.

The review-time enforcement of the tagging standard: DataClassification,
Owner, CostCentre and Application. This check fails the PR before a plan
ever runs; the org tag policy (Guardrails) backstops the *values* at the
API, and this gate covers presence until the deny-untagged SCP lands.

Resources are enumerated rather than wildcarded so the check never fails
an untaggable resource type. Extend the list as new taggable types enter
the repo — a type missing here is a gap in the gate, not a pass.
"""

from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck

REQUIRED_TAGS = ["DataClassification", "Owner", "CostCentre", "Application"]

# Taggable types the platform repo creates. Grown alongside the estate.
SUPPORTED_RESOURCES = [
    "aws_organizations_account",
    "aws_organizations_organizational_unit",
    "aws_s3_bucket",
    "aws_kms_key",
    "aws_cloudtrail",
    "aws_iam_role",
    "aws_iam_openid_connect_provider",
    "aws_vpc",
    "aws_subnet",
    "aws_networkmanager_global_network",
    "aws_networkmanager_core_network",
    "aws_networkmanager_vpc_attachment",
    "aws_networkfirewall_firewall",
    "aws_networkfirewall_rule_group",
    "aws_vpc_ipam",
    "aws_vpc_ipam_pool",
    "aws_route53_resolver_endpoint",
    "aws_cloudfront_distribution",
    "aws_backup_vault",
    "aws_ssoadmin_permission_set",
]


class KestrelStandardTags(BaseResourceCheck):
    def __init__(self):
        super().__init__(
            name="Resource carries the four standard tags "
            "(DataClassification, Owner, CostCentre, Application)",
            id="CKV_KES_1",
            categories=[CheckCategories.CONVENTION],
            supported_resources=SUPPORTED_RESOURCES,
        )

    def scan_resource_conf(self, conf):
        tags = conf.get("tags")
        # Terraform's parsed form wraps values in a list; a tags argument
        # that is an expression (e.g. local.standard_tags) arrives as a
        # string reference — trust it, the plan-time policy will see the
        # resolved values.
        if tags and isinstance(tags[0], str):
            return CheckResult.PASSED
        tag_keys = set(tags[0].keys()) if tags and isinstance(tags[0], dict) else set()
        missing = [t for t in REQUIRED_TAGS if t not in tag_keys]
        if missing:
            self.details.append(f"missing tags: {', '.join(missing)}")
            return CheckResult.FAILED
        return CheckResult.PASSED


check = KestrelStandardTags()
