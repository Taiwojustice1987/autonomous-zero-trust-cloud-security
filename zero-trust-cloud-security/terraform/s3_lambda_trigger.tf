############################################
# Permission: Allow S3 to Invoke Lambda
############################################
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.zero_trust_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.zero_trust_lambda_bucket.arn
}

############################################
# S3 → Lambda Trigger (ENABLED)
# Only trigger on uploads to incoming/
############################################
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.zero_trust_lambda_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.zero_trust_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "incoming/"
  }

  depends_on = [
    aws_lambda_permission.allow_s3
  ]
}
