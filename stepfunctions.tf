resource "aws_cloudwatch_log_group" "sfn_logs" {
  name              = "/aws/states/${var.project_name}-logs"
  retention_in_days = 14
  tags              = local.tags
}

resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.project_name}-state-machine"
  role_arn = aws_iam_role.sfn_role.arn

  definition = templatefile("${path.module}/sfn_definition.tpl.json", {
    ingest_arn  = aws_lambda_function.ingest.arn
    process_arn = aws_lambda_function.process.arn
    writer_arn  = aws_lambda_function.writer.arn
  })

  # Legacy logging config (compatible with your provider)
  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  # Ensure log group & role policy exist first
  depends_on = [
    aws_cloudwatch_log_group.sfn_logs,
    aws_iam_role_policy.sfn_policy
  ]

  tags = local.tags
}
