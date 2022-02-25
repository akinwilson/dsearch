variable "name" {
  description = "Name of stack module"
}

variable "environment" {
  description = "the name of your environment, e.g. 'production' or 'development'"
}

variable "vpc_id" {
  description = "The vpc to launch the EC2 instance into"
}

variable "subnet_id" {
  description = "The subnet (public) to launch the EC2 instance into"
}

variable "ami" {
  description = "Image to be used with ec2 instance"
  default     = "ami-0dd555eb7eb3b7c82"
}

variable "fs_id" {
  description = "id for filesystem"
}

variable "sg" {
  description = "ec2 security group"
}