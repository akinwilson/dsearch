variable "name" {
  description = "Name of stack module"
 
}
variable "environment" {
  description = "the name of your environment, e.g. \"prod\""
}

variable "region" {
  description = "the AWS region in which resources are created"
}

variable "subnets" {
  description = "List of subnet IDs"
}

variable "ecs_service_security_groups" {
  description = "Comma separated list of security groups"
}

variable "container_port" {
  description = "Port of container"
}

variable "container_cpu" {
  description = "The number of cpu units used by the task"
}

variable "container_memory" {
  description = "The amount (in MiB) of memory used by the task"
}

variable "retriever_container_repo" {
  description = "name of container within repo"
  default= "437996125465.dkr.ecr.eu-west-2.amazonaws.com"
}

variable "aws_alb_target_group_arn" {
  description = "ARN of the alb target group"
}

variable "service_desired_count" {
  description = "Number of services running in parallel"
}

variable "container_environment" {
  description = "The container environmnent variables"
  type        = list
}

# variable "container_secrets" {
#   description = "The container secret environmnent variables"
#   type        = list
# }

# variable "container_secrets_arns" {
#   description = "ARN for secrets"
# }

variable "aws_ecr_retriever_repo_url" {
  description = "URL of the repostory container the image to be served over ECS"
  default="437996125465.dkr.ecr.eu-west-2.amazonaws.com/e2e-search-retriever-prod:latest"
}



variable "fs_id" {
  description = "File system ID to use as mounting point when serving container"
}


variable "efs_access_point_id" {
  description = "File system ID to use as mounting point when serving container"
}

