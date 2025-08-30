# Zip Lambda code (root module layout)
data "archive_file" "ingest_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambdas/ingest"
  output_path = "${path.module}/build/ingest.zip"
}

data "archive_file" "process_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambdas/process"
  output_path = "${path.module}/build/process.zip"
}

data "archive_file" "writer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambdas/writer"
  output_path = "${path.module}/build/writer.zip"
}

resource "aws_lambda_function" "ingest" {
  function_name = "${var.project_name}-ingest"
  role          = aws_iam_role.ingest_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.ingest_zip.output_path
  timeout       = 30
  environment {
    variables = {
      RAW_BUCKET = aws_s3_bucket.raw.bucket
      RAW_PREFIX = "ingest/"
    }
  }
  tags = local.tags
}

resource "aws_lambda_function" "process" {
  function_name = "${var.project_name}-process"
  role          = aws_iam_role.process_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.process_zip.output_path
  timeout       = 60
  environment {
    variables = {
      RAW_BUCKET = aws_s3_bucket.raw.bucket
    }
  }
  tags = local.tags
}

resource "aws_lambda_function" "writer" {
  function_name = "${var.project_name}-writer"
  role          = aws_iam_role.writer_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.writer_zip.output_path
  timeout       = 60
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.user_activity.name
    }
  }
  tags = local.tags
}


# Allow Step Functions to invoke lambdas
resource "aws_lambda_permission" "allow_sfn_ingest" {
  statement_id  = "AllowSfnInvokeIngest"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "states.amazonaws.com"
  source_arn    = aws_sfn_state_machine.pipeline.arn
}

resource "aws_lambda_permission" "allow_sfn_process" {
  statement_id  = "AllowSfnInvokeProcess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process.function_name
  principal     = "states.amazonaws.com"
  source_arn    = aws_sfn_state_machine.pipeline.arn
}

resource "aws_lambda_permission" "allow_sfn_writer" {
  statement_id  = "AllowSfnInvokeWriter"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.writer.function_name
  principal     = "states.amazonaws.com"
  source_arn    = aws_sfn_state_machine.pipeline.arn
}
