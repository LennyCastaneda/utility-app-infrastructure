/******************************************************************************
* PROVIDERS
*******************************************************************************/

terraform {
  required_version = "~> 0.12.6"

  required_providers {
    aws = "~> 2.0"
  }
}

provider "aws" {
  version = "~> 2.0"
  region = var.region
}