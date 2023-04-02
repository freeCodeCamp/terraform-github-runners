# terraform-github-runners

> Our Terraform module to provision GitHub self-hosted runners on AWS.

This resources created by this config is based on the [Terraform module for scalable self hosted GitHub action runners](https://github.com/philips-labs/terraform-aws-github-runner) by [Philips Labs](https://github.com/philips-labs).

## Prerequisites

 - [Terraform](https://www.terraform.io/downloads.html) 1.0+
 - [Terraform Cloud](https://www.terraform.io/docs/cloud/index.html) account
 - [AWS](https://aws.amazon.com/) account, console access, and IAM credentials
 - GitHub App and GitHub App Private Key - See staff-wiki for more details

## Usage

Check the makefile for the available commands or run `make help` to see the available commands. More detailed instructions are available in the staff-wiki.

## Copyright & License

Copyright (c) 2023 freeCodeCamp.org - Released under the [BSD 3 license](LICENSE.md).
