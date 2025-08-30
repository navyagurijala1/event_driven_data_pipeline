variable "project_name" {
  description = "Project prefix"
  type        = string
  default     = "event-pipeline"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "alarm_email" {
  description = "Email to receive SNS alarms (leave empty to disable)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

