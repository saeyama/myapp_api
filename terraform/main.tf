terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = var.aws_profile
}

# ---------------------------------------------
# 1. Lambdaが動くための「許可証（IAMロール）」
# ---------------------------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "cognito-sync-lambda-role"

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

# LambdaがログをCloudWatchに書き込めるようにする権限
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------------------------
# 2. Lambdaに入れる実際のコード（lambda/ディレクトリをzip化）
# ---------------------------------------------
data "archive_file" "lambda" {
  type        = "zip"
  output_path = "lambda.zip"
  source_dir  = "${path.module}/lambda"
}

# ---------------------------------------------
# 3. Lambda関数本体
# ---------------------------------------------
resource "aws_lambda_function" "cognito_sync_lambda" {
  function_name = "cognito-sync-user"

  role = aws_iam_role.lambda_exec_role.arn

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "ruby3.2"
  handler = "lambda_function.handler"

  timeout = 10

  environment {
    variables = {
      RAILS_API_URL = var.rails_api_url
    }
  }
}

# ---------------------------------------------
# 4. 「このCognitoユーザープールからだけ呼び出してもいいよ」という許可設定
# ---------------------------------------------
resource "aws_lambda_permission" "allow_cognito" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_sync_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = "arn:aws:cognito-idp:ap-northeast-1:${var.aws_account_id}:userpool/${var.cognito_user_pool_id}"
}

# ---------------------------------------------
# 5. CognitoのPost-ConfirmationトリガーにLambdaを紐付ける
# ---------------------------------------------
resource "null_resource" "cognito_trigger" {
  triggers = {
    lambda_arn = aws_lambda_function.cognito_sync_lambda.arn
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws cognito-idp update-user-pool \
        --user-pool-id ${var.cognito_user_pool_id} \
        --lambda-config PostConfirmation=${aws_lambda_function.cognito_sync_lambda.arn} \
        --auto-verified-attributes email \
        --region ap-northeast-1 \
        --profile ${var.aws_profile}
    EOT
  }

  depends_on = [aws_lambda_permission.allow_cognito]
}
