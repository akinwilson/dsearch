resource "aws_key_pair" "main" {
  key_name   = "main-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDfxuPKIWcCq2TnchDWvN0JNa8RTCLmj9Oe3G0xig0FAeH7+1Op4eBcjzDcKInkF/WKTj7LNIFfkDNeMUr9oWUqhjpiU/DKM4SrMZnfGHylPXkNYdEW2rkGo7+7Da9vS+oO34jD9Qp8nmTvmMmSrYC2aN6WenB4pLDIrUvAsKL5ans+SQ1X8k/A5NQZKx8LBhGO2EdT9OukOK6A7z+F4IITPW7HhWppkn4ozcqX1sToiLSmD58WH/TgXicbvrFYmL5jAW5ikGiX9INMcKwk9OtVkYj2O2euLRCnqTqTp6US4UWL5hrYOYeh/asJ2tDyH47Io6TDo8eOu1A8EIh60n6c6oK+tTEbcunnxLrd+3pi/SmpKzOQFi1NZyn/Va5cdLxnx83/4TAwBUD8z0gU92R2KKl3HPd0y6ERJtHuKR7qXqDyxNhenY4BmKxkDzgsRYSSeR2rF25ZmuW8ExcbMGYl7fKVbkAaF9a/hkMTngfc33jNJ4juuHdei//IrsQzckk= akinwilson@Inspiron-7590"
}

resource "aws_security_group" "main" {
    name        = "AllowsEc2Connection"
    description = "Allow remote access to ec2 instance"
    vpc_id      = var.vpc_id
    egress = [
        {
        cidr_blocks      = [ "0.0.0.0/0", ]
        description      = ""
        from_port        = 0
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "-1"
        security_groups  = []
        self             = false
        to_port          = 0
        }
    ]
    ingress                = [
    {
        cidr_blocks      = [ "0.0.0.0/0", ]
        description      = ""
        from_port        = 22
        ipv6_cidr_blocks = []
        prefix_list_ids  = []
        protocol         = "tcp"
        security_groups  = []
        self             = false
        to_port          = 22
    }
    ]
}


resource "aws_security_group_rule" "efs" {
    security_group_id = aws_security_group.main.id
    cidr_blocks = ["0.0.0.0/0",]
    type = "egress"
    protocol         = "TCP"
    from_port        = 2049
    to_port          = 2049
    }


# eu-west-2b.fs-079b464d391415326efs.aws-eu-west-2.amazonaws.com

# remote-execute 
#  sudo yum -y update 
#  sudo yum -y install nfs-utils
# mkdir /mnt/efs
# sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport eu-west-2b.fs-079b464d391415326.efs.eu-west-2.amazonaws.com:/   /mnt/efs


resource "aws_instance" "main" {
  ami                    = var.ami
  instance_type          = "t2.micro"
  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name = aws_key_pair.main.key_name

  tags = {
  Name        = "${var.name}-ec2-${var.environment}"
  Environment = var.environment
  }
}

