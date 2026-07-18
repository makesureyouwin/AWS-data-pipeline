resource "aws_sfn_state_machine" "pipeline_state_machine" {
  name     = "pipeline-orchestrator"
  role_arn = aws_iam_role.stepfunctions_exec_role.arn

  definition = jsonencode({
    Comment = "Orchestrates Glue transform -> Redshift load, with failure handling"
    StartAt = "RunGlueJob"
    States = {
      RunGlueJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = "pipeline-etl-job"   # we'll create this Glue job in the next phase
        }
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "NotifyFailure"
          }
        ]
        Next = "PipelineSucceeded"
      }
      PipelineSucceeded = {
        Type = "Succeed"
      }
      NotifyFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = aws_sns_topic.pipeline_alerts.arn
          Message  = "Pipeline failed during Glue job execution. Check CloudWatch Logs."
        }
        End = true
      }
    }
  })
}

# SNS topic for failure alerts
resource "aws_sns_topic" "pipeline_alerts" {
  name = "pipeline-failure-alerts"
}

# IAM role for Step Functions itself
resource "aws_iam_role" "stepfunctions_exec_role" {
  name = "pipeline-stepfunctions-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "stepfunctions_permissions" {
  name = "allow-glue-and-sns"
  role = aws_iam_role.stepfunctions_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["glue:StartJobRun", "glue:GetJobRun"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.pipeline_alerts.arn
      }
    ]
  })
}