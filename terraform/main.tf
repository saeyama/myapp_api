terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
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
# 2. Lambdaに入れる「とりあえずのダミーコード」
# ---------------------------------------------
data "archive_file" "dummy_lambda" {
  type        = "zip"
  output_path = "dummy_lambda.zip"
  source {
    content  = "def handler(event:, context:)\n  puts 'Hello from Dummy Lambda!'\n  return event\nend"
    filename = "lambda_function.rb"
  }
}

# ---------------------------------------------
# 3. Lambda関数本体の作成（テスト用）
# ---------------------------------------------
resource "aws_lambda_function" "cognito_sync_lambda" {
  function_name = "cognito-sync-user"

  # ここで上の「1」で作ったロールを紐付けています！
  role = aws_iam_role.lambda_exec_role.arn

  filename         = data.archive_file.dummy_lambda.output_path
  source_code_hash = data.archive_file.dummy_lambda.output_base64sha256

  runtime = "ruby3.2"
  handler = "lambda_function.handler"
}

# ---------------------------------------------
# 4. 「Cognitoから呼び出してもいいよ」という許可設定
# ---------------------------------------------
resource "aws_lambda_permission" "allow_cognito" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_sync_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
}
