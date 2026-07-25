# Logging & Monitoring step 4 — every Session Manager session recorded.
#
# CloudTrail shows that a session STARTED; only recording shows what was
# typed inside it. For a PROTECTED estate reached exclusively through
# Session Manager (no bastions, no SSH keys), the session transcript is
# the interactive half of "who did what" — the half CloudTrail cannot
# answer.
#
# Set in the account's SSM preferences by the baseline, so there is no
# per-instance or per-account toggle: a session either records or does
# not start.

resource "aws_kms_key" "sessions" {
  description             = "SSE-KMS for Session Manager recordings — its own key, not the log sink's"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = var.tags
}

resource "aws_kms_alias" "sessions" {
  name          = "alias/kestrel-session-recording"
  target_key_id = aws_kms_key.sessions.key_id
}

resource "aws_ssm_document" "session_preferences" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session Manager preferences — recording to the log sink, KMS-encrypted, no exceptions."
    sessionType   = "Standard_Stream"

    inputs = {
      s3BucketName        = var.logs_bucket_name
      s3KeyPrefix         = "session-recordings/"
      s3EncryptionEnabled = true

      # Encrypting the session itself, not just the recording at rest —
      # the transcript is PROTECTED data in transit too.
      kmsKeyId = aws_kms_key.sessions.arn

      # No plain shell profile escape: idle sessions close rather than
      # sitting open on a credential nobody is watching.
      idleSessionTimeout = "20"
      maxSessionDuration = "240"

      runAsEnabled = false
    }
  })

  tags = var.tags
}
