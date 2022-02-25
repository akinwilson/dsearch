resource "aws_key_pair" "main" {
  key_name   = "main-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDfxuPKIWcCq2TnchDWvN0JNa8RTCLmj9Oe3G0xig0FAeH7+1Op4eBcjzDcKInkF/WKTj7LNIFfkDNeMUr9oWUqhjpiU/DKM4SrMZnfGHylPXkNYdEW2rkGo7+7Da9vS+oO34jD9Qp8nmTvmMmSrYC2aN6WenB4pLDIrUvAsKL5ans+SQ1X8k/A5NQZKx8LBhGO2EdT9OukOK6A7z+F4IITPW7HhWppkn4ozcqX1sToiLSmD58WH/TgXicbvrFYmL5jAW5ikGiX9INMcKwk9OtVkYj2O2euLRCnqTqTp6US4UWL5hrYOYeh/asJ2tDyH47Io6TDo8eOu1A8EIh60n6c6oK+tTEbcunnxLrd+3pi/SmpKzOQFi1NZyn/Va5cdLxnx83/4TAwBUD8z0gU92R2KKl3HPd0y6ERJtHuKR7qXqDyxNhenY4BmKxkDzgsRYSSeR2rF25ZmuW8ExcbMGYl7fKVbkAaF9a/hkMTngfc33jNJ4juuHdei//IrsQzckk= akinwilson@Inspiron-7590"
}

resource "aws_instance" "main" {
  ami                    = var.ami
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg]
  key_name               = aws_key_pair.main.key_name
  tags = {
    Name        = "${var.name}-ec2-${var.environment}"
    Environment = var.environment
  }
}

