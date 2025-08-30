# =========================
# Assume roles
# =========================
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "assume_sfn" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

# =========================
# Common Lambda logs policy
# =========================
data "aws_iam_policy_document" "lambda_logs" {
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

# =========================
# Ingest Lambda: write to S3
# =========================
data "aws_iam_policy_document" "ingest_access" {
  statement {
    actions   = ["s3:PutObject", "s3:PutObjectAcl"]
    resources = ["${aws_s3_bucket.raw.arn}/*"]
  }
}

resource "aws_iam_role" "ingest_role" {
  name               = "${var.project_name}-ingest-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "ingest_logs" {
  role   = aws_iam_role.ingest_role.id
  name   = "logs"
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "ingest_policy" {
  role   = aws_iam_role.ingest_role.id
  name   = "s3write"
  policy = data.aws_iam_policy_document.ingest_access.json
}

# =========================
# Process Lambda: read S3
# =========================
data "aws_iam_policy_document" "process_access" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.raw.arn}/*"]
  }
}

resource "aws_iam_role" "process_role" {
  name               = "${var.project_name}-process-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "process_logs" {
  role   = aws_iam_role.process_role.id
  name   = "logs"
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "process_policy" {
  role   = aws_iam_role.process_role.id
  name   = "s3read"
  policy = data.aws_iam_policy_document.process_access.json
}

# =========================
# Writer Lambda: write DynamoDB
# =========================
data "aws_iam_policy_document" "writer_access" {
  statement {
    actions   = ["dynamodb:BatchWriteItem", "dynamodb:PutItem"]
    resources = [aws_dynamodb_table.user_activity.arn]
  }
}

resource "aws_iam_role" "writer_role" {
  name               = "${var.project_name}-writer-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "writer_logs" {
  role   = aws_iam_role.writer_role.id
  name   = "logs"
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "writer_policy" {
  role   = aws_iam_role.writer_role.id
  name   = "ddbwrite"
  policy = data.aws_iam_policy_document.writer_access.json
}

# =========================
# Step Functions role + policy (FIXED)
# =========================
# Permissions for Step Functions to invoke Lambdas AND to use CloudWatch Logs "log delivery"
data "aws_iam_policy_document" "sfn_invoke" {
  # Invoke our Lambdas
  statement {
    actions = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.ingest.arn,
      aws_lambda_function.process.arn,
      aws_lambda_function.writer.arn
    ]
  }

  # CloudWatch Logs permissions for SFN logging (log-delivery APIs)
  # Some actions don't support resource-level ARNs -> use "*"
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",

      # Newer log-delivery APIs required by many services (incl. SFN)
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",

      # If you encrypt the log group with KMS, this is needed too:
      "logs:AssociateKmsKey"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "sfn_role" {
  name               = "${var.project_name}-sfn-role-${random_id.suffix.hex}"
  assume_role_policy = data.aws_iam_policy_document.assume_sfn.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "sfn_policy" {
  role   = aws_iam_role.sfn_role.id
  name   = "invoke-and-logs"
  policy = data.aws_iam_policy_document.sfn_invoke.json
}
