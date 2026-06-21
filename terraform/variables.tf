variable "rails_api_url" {
  description = "本番環境のRails API URL"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "CognitoユーザープールID"
  type        = string
}

variable "aws_account_id" {
  description = "AWSアカウントID"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLIプロファイル名"
  type        = string
}
