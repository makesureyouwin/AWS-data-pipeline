# The role Lambda assumes when it runs
resource "aws_iam_role" "lambda_exec_role" {
  name = "pipeline-lambda-exec-role"

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

# Basic permission every Lambda needs: write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom permission: allow this Lambda to start Step Functions executions
resource "aws_iam_role_policy" "lambda_stepfunctions_policy" {
  name = "allow-start-stepfunctions"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = "*"   # we'll narrow this to the specific state machine ARN once it's created
      }
    ]
  })
}

# Package the Lambda code into a zip automatically
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/trigger_pipeline.py"
  output_path = "${path.module}/../lambda/trigger_pipeline.zip"
}

# The actual Lambda function
resource "aws_lambda_function" "trigger_pipeline" {
  function_name = "pipeline-trigger"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "trigger_pipeline.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout = 30

  tags = {
    Project     = "AWS-data-pipeline"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Give S3 permission to invoke this specific Lambda function
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_pipeline.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw_data.arn
}

# Tell the S3 bucket to actually call the Lambda when a new file is created
resource "aws_s3_bucket_notification" "raw_data_trigger" {
  bucket = aws_s3_bucket.raw_data.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.trigger_pipeline.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}