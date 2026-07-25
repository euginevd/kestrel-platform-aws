# The sink's account, named once — every cross-leaf reference below
# derives from it rather than repeating the digits.
locals {
  log_archive_account_id = "223456789012"
}

locals {
  standard_tags = {
    DataClassification = "OFFICIAL"
    Owner              = "security-team@kestrel.com.au"
    CostCentre         = "CC-SECURITY"
    Application        = "landing-zone"
  }

  org_id = "o-kestrel00id"

  # The sink lives in log-archive (its own leaf, its own state). Cross-leaf
  # references are name-shaped and stable — bucket names and key aliases,
  # never generated IDs — so leaves stay independently appliable.
  logs_bucket_name   = "kestrel-org-cloudtrail-ap-southeast-2"
  logs_kms_alias_arn = "arn:aws:kms:ap-southeast-2:${local.log_archive_account_id}:alias/kestrel-org-logs"

  # The managed SOC — the far side of the seam (Monitoring decision 5).
  # Kestrel's Terraform reaches exactly this far: the connector queues
  # below and the Event Hub the bridge writes to. The DCR beyond is the
  # provider's, and the SLA measures the handoff. The Lake's own
  # subscriber is declared beside the Lake, in log-archive.
  soc_account_id = "334455667788"

  # Sources the Lake cannot carry, each needing its own SQS queue and S3
  # connector (Monitoring decision 6) — one queue per log type AND per S3
  # path, or the Sentinel connectors silently miss data.
  # Prefixes must match what actually writes there: the baseline's SSM
  # preferences write session transcripts to session-recordings/
  # (modules/account-baseline/sessions.tf), and log-archive's
  # connector_notifications fires the queue on that same prefix.
  connector_sources = {
    cloudwatch-app-logs = { prefix = "app-logs/" }           # via Microsoft's converter Lambda
    session-recordings  = { prefix = "session-recordings/" } # what was typed, not that a session began
    network-firewall    = { prefix = "firewall/" }           # alert + flow from the inspected exit
  }

  # Silence is a finding (decision 6): a source that stops writing is a
  # higher-severity event than most of what it records. Kestrel-only —
  # the provider cannot watch its own feed go quiet.
  silence_alarm_hours = 6
}
