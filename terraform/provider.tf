
terraform {

  #############################################################
  ## AFTER RUNNING TERRAFORM APPLY (WITH LOCAL BACKEND)
  ## YOU WILL UNCOMMENT THIS CODE THEN RERUN TERRAFORM INIT
  ## TO SWITCH FROM LOCAL BACKEND TO REMOTE AWS BACKEND
  #############################################################

  # backend "s3" {
  #   bucket                   = "steat-sj-terraform-tfstate"
  #   key                      = "production/terraform.tfstate"
  #   region                   = "us-east-1"
  #   shared_credentials_files = ["~/.aws/credentials"]
  #   profile                  = "terraform-sa"
  #   use_lockfile             = true
  #   encrypt                  = true
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.92.0"
    }
  }
}

#Configure the AWS Provider
provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  # profile                  = "terraform-sa"
}





