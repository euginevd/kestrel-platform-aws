# Logging & Monitoring step 9 — alarm the pipeline itself.
#
# DELIVERY FAILURE IS ITSELF AN ALARM (decision 6): a trail that stops
# writing is a higher-severity finding than most of what it records,
# because everything downstream keeps reporting healthy while the record
# quietly stops existing.
#
# KESTREL-ONLY, deliberately — the provider cannot watch its own feed go
# quiet. If the SOC is the thing that failed, an alarm that routes
# through the SOC proves nothing.

# --- Silence: no events in N hours, per source -------------------------------

resource "aws_cloudwatch_metric_alarm" "source_silent" {
  for_each = local.connector_sources

  alarm_name        = "kestrel-silent-${each.key}"
  alarm_description = "No objects delivered for ${each.key} in ${local.silence_alarm_hours}h — the source has gone quiet."

  namespace   = "AWS/SQS"
  metric_name = "NumberOfMessagesSent"
  dimensions  = { QueueName = aws_sqs_queue.connector[each.key].name }

  statistic           = "Sum"
  period              = local.silence_alarm_hours * 3600
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"

  # Silence produces NO datapoints, not a zero — treating missing data as
  # breaching is the whole point of this alarm.
  treat_missing_data = "breaching"

  alarm_actions = [aws_sns_topic.page.arn]

  tags = local.standard_tags
}

# --- The connector plumbing backing up ---------------------------------------

resource "aws_cloudwatch_metric_alarm" "queue_age" {
  for_each = local.connector_sources

  alarm_name        = "kestrel-queue-age-${each.key}"
  alarm_description = "Oldest message age on ${each.key} — the connector has stopped keeping up."

  namespace   = "AWS/SQS"
  metric_name = "ApproximateAgeOfOldestMessage"
  dimensions  = { QueueName = aws_sqs_queue.connector[each.key].name }

  statistic           = "Maximum"
  period              = 900
  evaluation_periods  = 2
  threshold           = 3600
  comparison_operator = "GreaterThanThreshold"

  alarm_actions = [aws_sns_topic.page.arn]

  tags = local.standard_tags
}

resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  for_each = local.connector_sources

  alarm_name        = "kestrel-dlq-${each.key}"
  alarm_description = "Anything in the ${each.key} DLQ is data that did not reach Sentinel."

  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"
  dimensions  = { QueueName = aws_sqs_queue.connector_dlq[each.key].name }

  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  alarm_actions = [aws_sns_topic.page.arn]

  tags = local.standard_tags
}

# --- The evidence plane going quiet ------------------------------------------

# The trail failing to deliver is the one alarm that must never depend on
# the trail: CloudTrail's own delivery-error metric, not a log query.
resource "aws_cloudwatch_metric_alarm" "trail_delivery" {
  alarm_name        = "kestrel-trail-delivery-failure"
  alarm_description = "The organisation trail is failing to deliver to log-archive."

  namespace   = "CloudTrailMetrics"
  metric_name = "S3DeliveryFailures"
  dimensions  = { TrailName = aws_cloudtrail.org.name }

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching" # no failures reported is the healthy case

  alarm_actions = [aws_sns_topic.page.arn]

  tags = local.standard_tags
}

# The tamper attempts from the success criteria: each one denied AND each
# one raising its own alert. The deny is the control; this is the proof
# anyone tried.
resource "aws_cloudwatch_event_rule" "tamper" {
  name        = "kestrel-evidence-tamper"
  description = "Attempts to stop the trail, shorten retention or delete archive objects — denied or not."

  event_pattern = jsonencode({
    source      = ["aws.cloudtrail", "aws.s3", "aws.config", "aws.kms"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "StopLogging",
        "DeleteTrail",
        "UpdateTrail",
        "PutObjectRetention",
        "PutBucketObjectLockConfiguration",
        "DeleteObjects",
        "StopConfigurationRecorder",
        "DeleteDeliveryChannel",

        # The archive CMK is the one path AROUND Object Lock: a locked
        # object encrypted with a disabled key is unreadable, which is
        # deletion by another name (Monitoring decision 6).
        "ScheduleKeyDeletion",
        "DisableKey",
        "DisableKeyRotation",
        "PutKeyPolicy",
      ]
    }
  })

  tags = local.standard_tags
}

resource "aws_cloudwatch_event_target" "tamper" {
  rule      = aws_cloudwatch_event_rule.tamper.name
  target_id = "sns-page"
  arn       = aws_sns_topic.page.arn
}
