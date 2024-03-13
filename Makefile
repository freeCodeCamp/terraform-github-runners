# Terraform module to create a CI runner on AWS
NAME := ci-runners-on-aws
SHELL := /bin/bash

# Variables
MK_lambdas_tag=$(shell grep -E "version" main.tf | cut -d "=" -f 2 | sed 's/"/"v/' | sed 's/"//g' | sed 's/ //g')
MK_github_app_id=$(GITHUB_APP_ID)
MK_github_app_key_base64=$(GITHUB_APP_KEY_BASE64)
MK_aws_profile=$(AWS_PROFILE)

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "Usage: make [Target] [Environment Variables]"
	@echo ""
	@echo "Targets:"
	@echo "  help             Show this help message"
	@echo "  init-lambdas     Initialize terraform in lambdas"
	@echo "  plan-lambdas     Plan terraform in lambdas"
	@echo "  download-lambdas Download lambdas"
	@echo "  init-runners     Initialize terraform in runners"
	@echo "  plan-runners     Plan terraform in runners"
	@echo "  apply-runners    Apply terraform in runners"
	@echo ""
	@echo "  upgrade          Get instructions to upgrade the runners"
	@echo ""
	@echo "  plan             Plan all"
	@echo "  destroy          Destroy all"
	@echo "  deploy           Deploy all"
	@echo ""
	@echo "Environment Variables:"
	@echo "  Copy the .terraform.tfvars.example to .terraform.tfvars and fill the variables"
	@echo ""
	@echo "Note:"
	@echo "  You can use the following command to get the base64 of your Github App Key:"
	@echo "    cat github-app-key.pem | base64 -w 0"


.PHONY: init-lambdas
init-lambdas:
	@echo "Initializing terraform in lambdas..."
	cd lambdas && terraform init -upgrade

.PHONY: plan-lambdas
plan-lambdas: init-lambdas
	@echo "Downloading lambdas version $(MK_lambdas_tag)..."
	cd lambdas && terraform plan -var "download_lambda_tag=$(MK_lambdas_tag)"

.PHONY: download-lambdas
download-lambdas: plan-lambdas
	cd lambdas && terraform apply -var "download_lambda_tag=$(MK_lambdas_tag)" -auto-approve
	@echo "Lambdas downloaded completed, check logs above for status!"

.PHONY: init-runners
init-runners:
	@echo "Initializing terraform in runners..."
	terraform init -upgrade

.PHONY: plan-runners
plan-runners: init-runners
	@echo "Planning terraform in runners..."
	terraform plan

.PHONY: apply-runners
apply-runners: plan-runners
	@echo "Applying terraform in runners..."
	terraform apply -auto-approve
	terraform output -raw webhook_secret

# Packer
.PHONY: packer
packer:
	@echo "Building packer image..."
	packer init ./packer/github-agent/ubuntu.pkr.hcl
	packer validate ./packer/github-agent/ubuntu.pkr.hcl
	packer build ./packer/github-agent/ubuntu.pkr.hcl

# Main targets

.PHONY: upgrade
upgrade:
	@echo ""
	@echo "To upgrade the runners, follow these steps:"
	@echo "Step 1: Update the GitHub runner version in the packer template."
	@echo "Step 2: Update the module version in main.tf,"
	@echo "        the lambdas version is sources from that in this makefile."
	@echo "Step 3: Run 'make packer' to build the new image."
	@echo "Step 4: Run 'make deploy' to deploy the new runners."

.PHONY: init
init: init-lambdas init-runners

.PHONY: plan
plan: download-lambdas plan-runners

.PHONY: deploy
deploy: download-lambdas apply-runners

.PHONY: destroy
destroy:
	@echo "Destroying runners..."
	terraform destroy -auto-approve
	@echo "Destroying lambdas..."
	cd lambdas && terraform destroy -var "download_lambda_tag=$(MK_lambdas_tag)" -auto-approve
