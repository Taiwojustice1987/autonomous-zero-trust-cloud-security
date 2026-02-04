###############################
# S3 Bucket for Lambda Storage
###############################
resource "aws_s3_bucket" "zero_trust_lambda_bucket" {
  # must be globally unique across ALL AWS accounts
  bucket = "zero-trust-lambda-bucket-unique123"

  tags = {
    Name    = "ZeroTrust-Lambda-Bucket"
    Purpose = "Store Lambda code and logs"
  }
}

# Block all public access (recommended; Zero Trust-friendly)
resource "aws_s3_bucket_public_access_block" "zero_trust_lambda_bucket_pab" {
  bucket = aws_s3_bucket.zero_trust_lambda_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###############################
# IAM Role for Lambda
###############################
resource "aws_iam_role" "lambda_role" {
  name = "ZeroTrustLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

###############################
# IAM Policy for Lambda (Least Privilege)
###############################
resource "aws_iam_role_policy" "lambda_policy" {
  name = "ZeroTrustLambdaPolicy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # --- Read only from incoming/ ---
      {
        Sid    = "ReadIncomingOnly"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.zero_trust_lambda_bucket.arn}/incoming/*"
      },

      # --- Write only to alerts/ ---
      {
        Sid    = "WriteAlertsOnly"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.zero_trust_lambda_bucket.arn}/alerts/*"
      },

      # --- Optional: allow listing the bucket but only for these prefixes ---
      {
        Sid    = "ListBucketRestrictedPrefixes"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.zero_trust_lambda_bucket.arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "incoming/*",
              "alerts/*"
            ]
          }
        }
      },

      # --- CloudWatch Logs ---
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

###############################
# Lambda Function (Autonomous Security Placeholder)
###############################
resource "aws_lambda_function" "zero_trust_lambda" {
  function_name = "zero_trust_anomaly_lambda"
  role          = aws_iam_role.lambda_role.arn

  # Your zip contains lambda_function.py with def lambda_handler(...)
  handler = "lambda_function.lambda_handler"
  runtime = "python3.11"

  # ✅ Improvement: avoid 3-second timeouts + give more CPU
  timeout     = 30
  memory_size = 256

  filename         = "lambda_function.zip" # must exist in terraform/
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.zero_trust_lambda_bucket.bucket
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.private_sg.id]
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_s3_bucket_public_access_block.zero_trust_lambda_bucket_pab
  ]
}

###############################
# Lambda Outputs
###############################
output "lambda_function_name" {
  value = aws_lambda_function.zero_trust_lambda.function_name
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "lambda_s3_bucket" {
  value = aws_s3_bucket.zero_trust_lambda_bucket.bucket
}
