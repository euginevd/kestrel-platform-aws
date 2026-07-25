# Logging & Monitoring decision 2 — classification enforced, not assumed.
#
# The trail's data-event selector matches buckets by NAME PREFIX
# (arn:aws:s3:::kestrel-protected-*, trail.tf). That is a convention, and
# a convention alone means a PROTECTED bucket named outside it would be
# logged as though it held nothing — a silent gap in exactly the control
# the data events exist to provide.
#
# Three layers, because no one of them is sufficient:
#   1. Convention NAMES it        — the prefix in the selector
#   2. Tag policy ENFORCES it     — DataClassification values on s3:bucket
#                                   (live/management/policies/tag-policy.tf)
#   3. This rule RECONCILES them  — a bucket tagged PROTECTED whose name
#                                   the selector would miss is non-compliant
#   4. Macie CHECKS THE HONESTY   — sampling the objects themselves rather
#                                   than trusting the label (detective.tf)

resource "aws_config_organization_custom_policy_rule" "protected_bucket_naming" {
  name = "kestrel-protected-buckets-match-trail-selector"

  resource_types_scope = ["AWS::S3::Bucket"]

  policy_runtime = "guard-2.x.x"
  policy_text    = <<-GUARD
    # A bucket carrying DataClassification=PROTECTED must be named so the
    # organisation trail's data-event selector actually matches it.
    # Failing this rule means object-level access to PROTECTED data is
    # going unrecorded.
    rule protected_buckets_are_logged {
      let classification = supplementaryConfiguration.Tags[
        this.key == "DataClassification"
      ].value

      when %classification == "PROTECTED" {
        resourceName == /^kestrel-protected-/
      }
    }
  GUARD

  trigger_types = ["ConfigurationItemChangeNotification"]

  # Excluded accounts: none. A brownfield account in Transitional is
  # exactly where an unconventionally-named PROTECTED bucket is most
  # likely to be, and this reporting is what the graduation review reads.

  depends_on = [aws_config_configuration_aggregator.org]
}
