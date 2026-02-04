resource "aws_lambda_function" "vpc_flow_monitor" {
  function_name = "vpc_flow_monitor"
  role          = aws_iam_role.lambda_role.arn

  # If your ZIP contains lambda_monitoring.py, keep this:
  handler = "lambda_monitoring.handler"
  runtime = "python3.11"

  # Terraform expects this zip to exist in the terraform/ folder
  filename         = "lambda_monitoring.zip"
  source_code_hash = filebase64sha256("lambda_monitoring.zip")

  environment {
    variables = {
      SOURCE_BUCKET = aws_s3_bucket.zero_trust_lambda_bucket.bucket
      ALERT_BUCKET  = aws_s3_bucket.zero_trust_lambda_bucket.bucket
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.private_sg.id]
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy
  ]
}
