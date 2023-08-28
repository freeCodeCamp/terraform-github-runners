resource "random_id" "random" {
  byte_length = 20
}

data "aws_caller_identity" "current" {}

resource "aws_resourcegroups_group" "resourcegroups_group" {
  name = "${var.prefix}-group"
  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters" : ["AWS::AllSupported"],
      "TagFilters" : [
        {
          "Key" : "GitHubRunner",
          "Values" : ["${var.prefix}"]
        }
      ]
    }
    JSON
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "${var.prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_dns_hostnames    = true
  enable_nat_gateway      = true
  map_public_ip_on_launch = false
  single_nat_gateway      = true
}

module "runners" {
  source                          = "philips-labs/github-runner/aws"
  version                         = "4.2.0"
  create_service_linked_role_spot = true
  aws_region                      = var.aws_region
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets

  prefix = var.prefix

  tags = {
    GitHubRunner = var.prefix
  }

  github_app = {
    key_base64     = var.github_app_key_base64
    id             = var.github_app_id
    webhook_secret = random_id.random.hex
  }

  # Grab zip files via the download-lambda module into the lambdas folder
  # See the makefile for more details
  webhook_lambda_zip                = "lambdas/webhook.zip"
  runner_binaries_syncer_lambda_zip = "lambdas/runner-binaries-syncer.zip"
  runners_lambda_zip                = "lambdas/runners.zip"

  enable_organization_runners = false
  runner_extra_labels         = "on-aws"

  # Run the GitHub actions agent as user.
  runner_run_as = "ubuntu"

  # enable access to the runners via SSM
  enable_ssm_on_runners = true

  minimum_running_time_in_minutes = 30

  # idle_config = [{
  #   # https://github.com/philips-labs/terraform-aws-github-runner#supported-config-
  #   # This is different from AWS Cron Expressions.
  #   cron      = "* * * * * *"
  #   timeZone  = "UTC"
  #   idleCount = 2
  # }]

  instance_types = ["c5.large"]

  # Use the latest Ubuntu 20.04 AMI from our account
  # built using the packer template in the packer folder
  ami_filter = {
    name  = ["github-runner-ubuntu-focal-amd64-*"]
    state = ["available"]
  }
  ami_owners      = [data.aws_caller_identity.current.account_id]
  enable_userdata = false

  block_device_mappings = [{
    # Set the block device name for Ubuntu root device
    device_name           = "/dev/sda1"
    delete_on_termination = true
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    iops                  = null
    throughput            = null
    kms_key_id            = null
    snapshot_id           = null
  }]

  runner_log_files = [
    {
      "log_group_name" : "syslog",
      "prefix_log_group" : true,
      "file_path" : "/var/log/syslog",
      "log_stream_name" : "{instance_id}"
    },
    {
      "log_group_name" : "user_data",
      "prefix_log_group" : true,
      "file_path" : "/var/log/user-data.log",
      "log_stream_name" : "{instance_id}/user_data"
    },
    {
      "log_group_name" : "runner",
      "prefix_log_group" : true,
      "file_path" : "/opt/actions-runner/_diag/Runner_**.log",
      "log_stream_name" : "{instance_id}/runner"
    }
  ]

  # disable binary syncer since github agent is already installed in the AMI.
  enable_runner_binaries_syncer = false

  # override delay of events in seconds
  delay_webhook_event   = 5
  runners_maximum_count = 10

  # set up a fifo queue to remain order
  enable_fifo_build_queue = true

  # enable ephemeral runners
  enable_ephemeral_runners = false

  # More on AWS Cron Expressions: https://stackoverflow.com/a/39508593/1932901
  # Will scale down to minimum runners if there are no builds in the queue in the last 1 hours
  scale_down_schedule_expression = "cron(0 0/1 * * ? *)"

  log_level = "debug"
}
