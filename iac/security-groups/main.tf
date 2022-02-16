resource "aws_security_group" "alb" {
  name   = "${var.name}-sg-alb-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.name}-sg-alb-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "${var.name}-sg-task-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = var.container_port
    to_port          = var.container_port
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.name}-sg-task-${var.environment}"
    Environment = var.environment
  }
}


resource "aws_security_group_rule" "lambda-efs-sg" {
    # name   = "${var.name}-lambda-efs-${var.environment}"
    # vpc_id = var.vpc_id
    security_group_id = aws_security_group.efs.id
    source_security_group_id = aws_security_group.lambda.id
    type = "egress"
    protocol         = "tcp"
    from_port        = 0
    to_port          = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }


resource "aws_security_group" "efs" {
  
  name   = "${var.name}-sg-efs-${var.environment}"
  vpc_id = var.vpc_id
  # ingress {
  #     security_groups = [aws_security_group.lambda.id]
  #     protocol         = "tcp"
  #     from_port        = 0
  #     to_port          = -1
  #     cidr_blocks      = ["0.0.0.0/0"]
  #     ipv6_cidr_blocks = ["::/0"]
  #   }
  egress {
      security_groups = [aws_security_group.ecs_tasks.id]
      protocol         = "-1"
      from_port        = 0
      to_port          = -1
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  tags = {
  Name        = "${var.name}-sg-efs-${var.environment}"
  Environment = var.environment
  }
}

resource "aws_security_group" "lambda" {
    name   = "${var.name}-sg-lambda-${var.environment}"
    vpc_id = var.vpc_id
    ingress {
      protocol         = "tcp"
      from_port        = 0
      to_port          = -1
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    egress {
      security_groups = [aws_security_group.efs.id] 
      protocol         = "-1"
      from_port        = 0
      to_port          = -1
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  tags = {
  Name        = "${var.name}-sg-lambda-${var.environment}"
  Environment = var.environment
  }
}


output "lambda" {
  value = aws_security_group.lambda.id
  
}

output "efs" {
  value = aws_security_group.efs.id 
}

output "alb" {
  value = aws_security_group.alb.id
}

output "ecs_tasks" {
  value = aws_security_group.ecs_tasks.id
}

