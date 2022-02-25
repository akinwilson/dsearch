variable "name" {
  description = "Name of stack module"
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod\""
}

variable "vpc_id" {
  description = "The VPC ID"
}

variable "container_port" {
  description = "Ingres and egress port of the container"
}

variable "lambda_port" {
  description = "Ingress and egress port for lambda"
  default     = 9003
}