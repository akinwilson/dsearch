terraform {
  backend "s3" {
    bucket = "infra-euw2"
    key    = "terraform-svc"
    region = "eu-west-2"
    # dynamodb_table = "terraform-state-lock-dynamo" #- uncomment this line once the terraform-state-lock-dynamo has been terraformed
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.73.0"
    }
  }
  required_version = ">=1.1.0"
}

provider "aws" {
  region = "eu-west-2"
}


resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name           = "terraform-state-lock-dynamo"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "DynamoDB Terraform State Lock Table"
  }
}

module "vpc" {
  source             = "./vpc"
  name               = var.name
  cidr               = var.cidr
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  availability_zones = var.availability_zones
  environment        = var.environment
}

module "ec2" {
  source      = "./ec2"
  name        = var.name
  environment = var.environment
  vpc_id      = module.vpc.id
  subnet_id   = module.vpc.public_subnets.1.id
  sg          = module.security_groups.ec2
  fs_id       = module.efs.fs.id
}

module "security_groups" {
  source         = "./security-groups"
  name           = var.name
  vpc_id         = module.vpc.id
  environment    = var.environment
  container_port = var.container_port
}

module "alb" {
  source              = "./alb"
  name                = var.name
  vpc_id              = module.vpc.id
  subnets             = module.vpc.public_subnets
  environment         = var.environment
  alb_security_groups = [module.security_groups.alb]
  # alb_tls_cert_arn    = var.tsl_certificate_arn
  health_check_path = var.health_check_path
}

module "ecr" {
  source      = "./ecr"
  name        = var.name
  environment = var.environment
}

module "efs" {
  source      = "./efs"
  name        = var.name
  environment = var.environment
  vpc_id      = module.vpc.id
  subnets     = module.vpc.private_subnets
  sg          = [module.security_groups.efs, module.security_groups.ec2]
}



module "ecs" {
  source                      = "./ecs"
  name                        = var.name
  environment                 = var.environment
  region                      = var.aws-region
  subnets                     = module.vpc.private_subnets
  aws_alb_target_group_arn    = module.alb.aws_alb_target_group_arn
  ecs_service_security_groups = [module.security_groups.ecs_tasks]
  container_port              = var.container_port
  container_cpu               = var.container_cpu
  container_memory            = var.container_memory
  service_desired_count       = var.service_desired_count
  container_environment = [
    { name = "LOG_LEVEL",
    value = "DEBUG" },
    { name = "PORT",
    value = var.container_port }
  ]
  aws_ecr_retriever_repo_url = module.ecr.aws_ecr_retriever_repo_url
  fs                         = module.efs.fs
  ap                         = module.efs.ap
}


module "lambda" {
  source            = "./lambda"
  name              = var.name
  environment       = var.environment
  subnets           = [module.vpc.private_subnets.1.id, module.vpc.private_subnets.2.id]
  efs_mount_path    = "/mnt/efs"
  access_point      = module.efs.access_point
  dependency_on_mnt = module.efs.depdency_on_mnt
  dependency_on_ecr = module.ecr.dependency_on_ecr
  sg                = module.security_groups.lambda
}


data "aws_iam_policy_document" "iam_policy_document" {
  statement {
    sid     = "AllowSpecificS3FullAccess"
    actions = ["s3:*"]
    effect  = "Allow"
    resources = [
      "arn:aws:s3:::*/*",
      "arn:aws:s3:::*",
      "arn:aws:s3:::infra-euw2",
      "arn:aws:s3:::infra-euw2",
    ]
  }

  statement {
    sid = "AllowSecurityGroups"
    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSecurityGroupsRules",
      "ec2:DescribeTags",
      "ec2:CreateTags",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:ModifySecurityGroupEgress",
      "ec2:ModifySecurityGroupRuleDescriptionIngress",
      "ec2:ModifySecurityGroupRuleDescriptionEgress",
      "ec2:ModifySecurityGroupRules",
      "ec2:CreateSecurityGroup"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "AllowEC2"
    actions = [
      "ec2:*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "AllowIAM"
    actions = [
      "iam:*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "AllowSecretsManager"
    actions = [
      "secretsmanager:*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "AllowSSM"
    actions = [
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:DeleteParameters",
      "ssm:DescribeParameters",
      "ssm:AddTagsToResource",
      "ssm:ListTagsForResource"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "iam_policy" {
  name   = "terraform-iam-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.iam_policy_document.json
}

resource "aws_iam_user" "terraform_agent_user" {
  name = "terraform_agent_user"
}
resource "aws_iam_user_policy_attachment" "tf_attach" {
  user       = aws_iam_user.terraform_agent_user.name
  policy_arn = aws_iam_policy.iam_policy.arn
}
