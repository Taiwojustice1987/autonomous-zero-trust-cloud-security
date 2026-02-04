# AWS region
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# Lambda function configuration
variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "zero_trust_lambda"
}

variable "lambda_handler" {
  description = "Handler for Lambda function"
  type        = string
  default     = "index.handler"
}

variable "lambda_runtime" {
  description = "Runtime for Lambda function"
  type        = string
  default     = "python3.11"
}

variable "lambda_zip_file" {
  description = "Path to Lambda zip file"
  type        = string
  default     = "lambda_function.zip"
}

# IAM Role Name
variable "iam_role_name" {
  description = "IAM role name for Lambda"
  type        = string
  default     = "lambda_s3_secure_role"
}

# S3 Bucket Name
variable "s3_bucket_name" {
  description = "S3 bucket name for Lambda access"
  type        = string
  default     = "zero-trust-lambda-bucket-unique123" # must be globally unique
}
