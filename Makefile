# Terraform module to create a CI runner on AWS
NAME := ci-runners-on-aws
SHELL := /bin/bash

# Variables
MK_lambdas_tag=$(shell grep -E "version" main.tf | cut -d "=" -f 2 | sed 's/"/"v/' | sed 's/"//g' | sed 's/ //g')

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
	@echo "  deploy           Deploy all"
	@echo ""
	@echo ""
	@echo "Example:"
	@echo "  make deploy"
	@echo ""
	@echo "Note:"
	@echo "  You can use the following command to get the base64 of your Github App Key:"
	@echo "    cat github-app-key.pem | base64 -w 0"
	@echo ""
	@echo "Warning:"
	@echo "  You should setup the AWS CLI Profile and signed into Terraform Cloud before running any commands."

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
	terraform apply
	terraform output -raw webhook_secret

.PHONY: deploy
deploy: download-lambdas apply-runners
