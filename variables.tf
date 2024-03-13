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

variable "prefix" {
  description = "Prefix used for resource naming."
  type        = string
  default     = "gh-runner"
}

variable "aws_region" {
  description = "AWS region to create the VPC, assuming zones `a` and `b` exists."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "shmar24" # Self Hosted March 2024
}

variable "tagr_version" {
  description = "Version of the GitHub Runner to download"
  type        = string
  default     = "5.8.0"
}
