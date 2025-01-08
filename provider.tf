terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.80.0" # to select version, to store state file on s3 backend 
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.region_name
  #profile = "RekaNV"  # Replace with your desired profile name
  
}


