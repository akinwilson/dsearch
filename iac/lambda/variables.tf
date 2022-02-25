variable "name" {
  description = "Name of module"
}

variable "environment" {
  description = "The environment to which the stack is deployed"
}

variable "indexer_container_repo" {
  description = "indexer image uri (from ECR) for lambda to pull image from"
  default     = "437996125465.dkr.ecr.eu-west-2.amazonaws.com"
}

variable "subnets" {
  description = "Ids of lambda subnets"
}

variable "efs_mount_path" {
  description = "The path the lambda function will mount the EFS to"
  default     = "/mnt/efs"
}

variable "master_key" {
  description = "Master key for secure communcation for indexer and retriever functions"
  default     = "_CBDdMT1hiwGuiTG4mWaXA"
}

variable "access_point" {
  description = "The arn of the access point for the lambda"
}

variable "dependency_on_mnt" {
  description = "dependency confirmation to lambda that EFS has been mount"
}

variable "dependency_on_ecr" {
  description = "dependency confirmation to lambda that ecr has been populated with image"
}


variable "sg" {
  description = "security group for lambda function to communicate with EFS"
}

