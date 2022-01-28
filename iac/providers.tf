terraform {
  backend "s3" {
      bucket = "search-infra-euw2"
      key = "iac-user"
      region = "eu-west-2"
  }
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "3.73.0"
    }
  }
  required_version = ">=1.1.0"
}

provider "aws" {
    region = "eu-west-2"
}

