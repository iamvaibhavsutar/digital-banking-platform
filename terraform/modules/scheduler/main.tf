variable "name"         { type = string }
variable "instance_ids" { type = list(string) }
variable "rds_id"       { type = string }

data "aws_caller_identity" "me" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sched" {
  name               = "${var.name}-nightly-stop"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy" "sched" {
  role = aws_iam_role.sched.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ec2:StopInstances"],
        Resource = [for id in var.instance_ids : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.me.account_id}:instance/${id}"] },
      { Effect = "Allow", Action = ["rds:StopDBInstance"],
        Resource = "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.me.account_id}:db:${var.rds_id}" }
    ]
  })
}

resource "aws_scheduler_schedule" "stop_ec2" {
  name                         = "${var.name}-stop-ec2"
  schedule_expression          = "cron(30 23 * * ? *)" # 23:30 every night
  schedule_expression_timezone = "Asia/Kolkata"
  flexible_time_window { mode = "OFF" }
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.sched.arn
    input    = jsonencode({ InstanceIds = var.instance_ids })
  }
}

resource "aws_scheduler_schedule" "stop_rds" {
  name                         = "${var.name}-stop-rds"
  schedule_expression          = "cron(35 23 * * ? *)"
  schedule_expression_timezone = "Asia/Kolkata"
  flexible_time_window { mode = "OFF" }
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    role_arn = aws_iam_role.sched.arn
    input    = jsonencode({ DbInstanceIdentifier = var.rds_id })
  }
}
