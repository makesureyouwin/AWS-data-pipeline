resource "aws_redshiftserverless_namespace" "pipeline_ns" {
  namespace_name      = "pipeline-namespace"
  db_name             = "pipelinedb"
  admin_username      = "pipelineadmin"
  admin_user_password = var.redshift_admin_password
  iam_roles           = [aws_iam_role.redshift_s3_role.arn]
}

resource "aws_redshiftserverless_workgroup" "pipeline_wg" {
  namespace_name       = aws_redshiftserverless_namespace.pipeline_ns.namespace_name
  workgroup_name       = "pipeline-workgroup"
  base_capacity        = 8
  publicly_accessible  = false
}

variable "redshift_admin_password" {
  type      = string
  sensitive = true
}

resource "aws_iam_role" "redshift_s3_role" {
  name = "pipeline-redshift-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "redshift_s3_read" {
  name = "allow-s3-read"
  role = aws_iam_role.redshift_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.raw_data.arn,
          "${aws_s3_bucket.raw_data.arn}/*"
        ]
      }
    ]
  })
}