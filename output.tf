output "raw_bucket_name" {
  value = aws_s3_bucket.raw.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.user_activity.name
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.pipeline.arn
}

