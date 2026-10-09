# Add-on file for your EXISTING monitoring module.
# Assumes: var.name, aws_sns_topic.alerts, and an aws_cloudtrail "this" resource already exist.
# In that aws_cloudtrail "this" block, ADD these two lines:
#   cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trail.arn}:*"
#   cloud_watch_logs_role_arn  = aws_iam_role.trail_logs.arn

resource "aws_cloudwatch_log_group" "trail" {
  name              = "/banking/cloudtrail"
  retention_in_days = 14
}

data "aws_iam_policy_document" "trail_logs_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "trail_logs" {
  name               = "${var.name}-cloudtrail-to-cwlogs"
  assume_role_policy = data.aws_iam_policy_document.trail_logs_trust.json
}

resource "aws_iam_role_policy" "trail_logs" {
  role = aws_iam_role.trail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.trail.arn}:*"
    }]
  })
}

locals {
  security_alarms = {
    root_usage = {
      pattern   = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
      threshold = 1
    }
    unauthorized_calls = {
      pattern   = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
      threshold = 10
    }
    console_login_no_mfa = {
      pattern   = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") && ($.userIdentity.type = \"IAMUser\") }"
      threshold = 1
    }
    sg_changes = {
      pattern   = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
      threshold = 1
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "sec" {
  for_each       = local.security_alarms
  name           = "sec-${each.key}"
  log_group_name = aws_cloudwatch_log_group.trail.name
  pattern        = each.value.pattern
  metric_transformation {
    name      = each.key
    namespace = "BankingSecurity"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "sec" {
  for_each            = local.security_alarms
  alarm_name          = "sec-${each.key}"
  namespace           = "BankingSecurity"
  metric_name         = each.key
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = each.value.threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
