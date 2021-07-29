#!/bin/bash
# init to ensure we have proper providers
terraform -chdir=terraform init
# run the plan to ensure we have proper configuration
terraform -chdir=terraform plan -input=false -var-file=../admin.auto.tfvars
# pause to allow escape to clear errors
#read -p "Press enter to continue"
# apply
terraform -chdir=terraform apply -var-file=../admin.auto.tfvars --auto-approve
