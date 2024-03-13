variable "github_app_key_base64" {
  description = "base64 encoded private key of the GitHub App"
  type        = string
  sensitive   = true
}

variable "github_app_id" {
  description = "value of the GitHub App ID"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region to use for Terraform"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key_id" {
  description = "The value of the AWS Access Key ID."
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "The value of the AWS Secret Access Key."
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name to use for tagging resources"
  type        = string
  default     = "ubuntu"
}

variable "runner_os" {
  description = "The OS to use for the runners"
  default     = "linux"
  type        = string
}
