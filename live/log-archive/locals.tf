locals {
  standard_tags = {
    DataClassification = "OFFICIAL"
    Owner              = "security-team@kestrel.com.au"
    CostCentre         = "CC-SECURITY"
    Application        = "landing-zone"
  }

  org_id                = "o-kestrel00id"
  management_account_id = "123456789012"
  trail_arn             = "arn:aws:cloudtrail:ap-southeast-2:323456789012:trail/kestrel-org" # owned by security-tooling

  # security-tooling writes and reads THROUGH the archive key but never
  # administers it — the separation Monitoring decision 1 turns from a
  # convention into a key policy.
  security_tooling_account_id = "323456789012"

  # The managed SOC — the far side of the seam (Monitoring decision 5).
  # It subscribes to the Lake; it never reaches the archive itself.
  soc_account_id  = "334455667788"
  soc_external_id = "kestrel-soc-ocsf"

  # The Sentinel S3 connectors read THIS bucket, on notifications to
  # queues owned by security-tooling (Monitoring decision 6). One prefix
  # per log type, because one queue per log type AND per S3 path is what
  # stops a connector silently missing data. Keep in step with
  # live/security-tooling/locals.tf → connector_sources.
  connector_notifications = {
    cloudwatch-app-logs = "app-logs/"
    session-recordings  = "session-recordings/"
    network-firewall    = "firewall/"
  }
}
