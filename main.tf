provider "aws" {
  region = local.region
}

provider "aws" {
  alias  = "sydney"
  region = "ap-southeast-2"
}

provider "aws" {
  alias  = "useast"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}



locals {
  region = "ap-southeast-2"
  name   = "ecs-anyhoo"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

#   container_name = "ecsdemo-frontend"
#   container_port = 3000

  tags = {
    Name       = local.name
    # Example    = local.name
    Repo = "https://github.com/jorke/ecs-anywhere-gpu"
  }
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}


output "cloudwatch_logs" {
  value = aws_cloudwatch_log_group.this.name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}