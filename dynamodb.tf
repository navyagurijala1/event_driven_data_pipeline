resource "aws_dynamodb_table" "user_activity" {
  name         = "${var.project_name}-user-activity"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "event_time"

  attribute {
    name = "user_id"
    type = "S"
  }
  attribute {
    name = "event_time"
    type = "S"
  }

  tags = local.tags
}

