# Upload the Glue PySpark script to S3
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.raw_data.id
  key    = "scripts/etl_job.py"
  source = "${path.module}/../glue/etl_job.py"
  etag   = filemd5("${path.module}/../glue/etl_job.py")
}

# IAM role for Glue
resource "aws_iam_role" "glue_exec_role" {
  name = "pipeline-glue-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

# AWS-managed policy with the baseline permissions Glue needs
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Custom permission: allow Glue to read/write our specific S3 bucket
resource "aws_iam_role_policy" "glue_s3_access" {
  name = "allow-s3-read-write"
  role = aws_iam_role.glue_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.raw_data.arn,
          "${aws_s3_bucket.raw_data.arn}/*"
        ]
      }
    ]
  })
}

# The Glue Job itself
resource "aws_glue_job" "etl_job" {
  name     = "pipeline-etl-job"
  role_arn = aws_iam_role.glue_exec_role.arn

  command {
    script_location = "s3://${aws_s3_bucket.raw_data.id}/scripts/etl_job.py"
    python_version   = "3"
  }

  default_arguments = {
    "--source_path"      = "s3://${aws_s3_bucket.raw_data.id}/incoming/"
    "--target_path"      = "s3://${aws_s3_bucket.raw_data.id}/processed/"
    "--job-language"      = "python"
  }

  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  timeout           = 10

  tags = {
    Project     = "real-aws-data-pipeline"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}