############################################
# S3 Bucket Policy (Defense-in-depth)
# Allows Lambda role to read incoming/* and write alerts/*
############################################
resource "aws_s3_bucket_policy" "zero_trust_bucket_policy" {
  bucket = aws_s3_bucket.zero_trust_lambda_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowLambdaReadIncoming"
        Effect   = "Allow"
        Principal = { AWS = aws_iam_role.lambda_role.arn }
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.zero_trust_lambda_bucket.arn}/incoming/*"
      },
      {
        Sid      = "AllowLambdaWriteAlerts"
        Effect   = "Allow"
        Principal = { AWS = aws_iam_role.lambda_role.arn }
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.zero_trust_lambda_bucket.arn}/alerts/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.zero_trust_lambda_bucket_pab
  ]
}
