# Lambda function for automatic deployment
resource "aws_lambda_function" "deploy_function" {
  filename      = "deploy_lambda.zip"
  function_name = "sttf-deploy-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.8"
  timeout       = 300

  environment {
    variables = {
      STAGING_INSTANCE_ID = aws_instance.sttf_api_staging.id
      PROD_INSTANCE_ID    = aws_instance.sttf_api_prod.id
      ECR_REPOSITORY_URL  = aws_ecr_repository.sttf_api.repository_url
      DEPLOYMENT_REGION   = "eu-central-1"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy,
    data.archive_file.lambda_zip
  ]
}

# Create the Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "deploy_lambda.zip"
  source {
    content = templatefile("${path.module}/lambda_function.py", {
      staging_instance_id = aws_instance.sttf_api_staging.id
      prod_instance_id    = aws_instance.sttf_api_prod.id
      ecr_repository_url  = aws_ecr_repository.sttf_api.repository_url
      aws_region          = "eu-central-1"
    })
    filename = "index.py"
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "sttf-lambda-role"

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

# Attach policies to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for Lambda to access EC2 and ECR
resource "aws_iam_role_policy" "lambda_custom_policy" {
  name = "sttf-lambda-custom-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:SendCommand",
          "ec2:ListCommandInvocations",
          "ssm:SendCommand",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation",
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge rule for ECR image push events
resource "aws_cloudwatch_event_rule" "ecr_push_rule" {
  name        = "sttf-ecr-push-rule"
  description = "Trigger deployment when new image is pushed to ECR"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Action"]
    detail = {
      action-type     = ["PUSH"]
      repository-name = [aws_ecr_repository.sttf_api.name]
      image-tag       = ["latest", "prod"]
    }
  })
}

# EventBridge target to invoke Lambda function
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.ecr_push_rule.name
  target_id = "DeployLambdaTarget"
  arn       = aws_lambda_function.deploy_function.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deploy_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecr_push_rule.arn
}