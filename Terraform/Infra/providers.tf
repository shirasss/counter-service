terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "counter-terraform-state-store"
    key            = "infra/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "counter-terraform-lock"
    encrypt        = true

  }

}

provider "aws" {
  region = "eu-west-2"
}



