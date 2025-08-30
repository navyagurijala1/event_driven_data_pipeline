# SNS topic for alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-alarms"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email_sub" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Lambda error alarms
resource "aws_cloudwatch_metric_alarm" "ingest_errors" {
  alarm_name          = "${var.project_name}-ingest-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Ingest Lambda reported errors"
  dimensions          = { FunctionName = aws_lambda_function.ingest.function_name }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "process_errors" {
  alarm_name          = "${var.project_name}-process-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Process Lambda reported errors"
  dimensions          = { FunctionName = aws_lambda_function.process.function_name }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "writer_errors" {
  alarm_name          = "${var.project_name}-writer-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Writer Lambda reported errors"
  dimensions          = { FunctionName = aws_lambda_function.writer.function_name }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"
  tags                = local.tags
}

# Step Functions failed executions
resource "aws_cloudwatch_metric_alarm" "sfn_failed" {
  alarm_name          = "${var.project_name}-sfn-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "State machine had failed executions"
  dimensions          = { StateMachineArn = aws_sfn_state_machine.pipeline.arn }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"
  tags                = local.tags
}
