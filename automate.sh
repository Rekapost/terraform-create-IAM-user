#!/bin/bash

# Assume the role
CREDS_JSON=$(aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/MyTerraformRole \
  --role-session-name MySession)

# Extract the temporary credentials
AWS_ACCESS_KEY_ID=$(echo $CREDS_JSON | jq -r .Credentials.AccessKeyId)
AWS_SECRET_ACCESS_KEY=$(echo $CREDS_JSON | jq -r .Credentials.SecretAccessKey)
AWS_SESSION_TOKEN=$(echo $CREDS_JSON | jq -r .Credentials.SessionToken)

# Set the environment variables
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN
export AWS_DEFAULT_REGION="us-west-2"

# Run Terraform command
terraform apply -auto-approve
