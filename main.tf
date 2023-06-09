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

provider "cloudinit" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

// aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended --region ap-southeast-2
data "aws_ssm_parameter" "gpu_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended"
}


locals {
  region = "ap-southeast-2"
  name   = "ecs-anyhoo"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  cluster_max             = 2
  cluster_min             = 0
  on_demand_base_capacity = 50
  spot_capacity           = 50
  spot                    = true
  allow_ips               = var.allow_ips
  // utilisation of the cluster
  target_capacity = "100"
  key_pair        = var.key_pair

  tags = {
    project = local.name
    Repo = "https://github.com/jorke/ecs-anywhere-gpu"
  }
}

resource "aws_security_group" "this" {
  name   = local.name
  vpc_id = module.vpc.vpc_id
  tags   = local.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.allow_ips
    self        = true
  }




  lifecycle {
    ignore_changes = [
      vpc_id,
    ]
  }
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs            = local.azs
  public_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  map_public_ip_on_launch = true



  tags           = local.tags
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  tags              = local.tags
}

resource "aws_vpc_endpoint" "ecr" {
  vpc_id              = module.vpc.vpc_id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${local.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.this.id]
  tags                = local.tags
}

resource "aws_vpc_endpoint" "ecr-api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.this.id]
  tags                = local.tags
}

resource "aws_vpc_endpoint" "ecs_agent" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ecs-agent"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.this.id]
  tags                = local.tags
}

resource "aws_vpc_endpoint" "ecs_telemetry" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${local.region}.ecs-telemetry"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.this.id]
  tags                = local.tags
}

variable "allow_ips" {
  type    = list(string)
  default = [""]
}

variable "key_pair" {
  type    = string
  default = ""

}
output "cloudwatch_logs" {
  value = aws_cloudwatch_log_group.this.name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}