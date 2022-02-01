variable "name" {
  description= "Name of module"
}

variable "environment" {
  description = "The environment to which the stack is deployed"
}

variable "indexer_image_uri" {
  description = "indexer image uri (from ECR) for lambda to pull image from"
}

variable "subnets" {
    description = "Ids of lambda subnets"
}

variable "efs_mount_path" {
  description = "The path the lambda function will mount the EFS to"
}

variable "master_key" {
  description= "Master key for secure communcation for indexer and retriever functions"
}

variable "access_point_lambda_arn" {
  description = "The arn of the access point for the lambda"
}



variable "dependency_on_mnt" {
  description = "dependency confirmation to lambda that EFS has been mount"
}

variable "sg_lambda_efs" {
    description = "security group for lambda function to communicate with EFS"
}