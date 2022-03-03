resource "aws_lb" "main" {
  name               = "${var.name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.alb_security_groups
  subnets            = var.subnets.*.id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.name}-alb-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_alb_target_group" "main" {
  name        = "${var.name}-tg-${var.environment}"
  port        = 7700
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "${var.name}-tg-${var.environment}"
    Environment = var.environment
  }
}

# https listener
resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.main.id
  port              = 443
  protocol          = "HTTPS"
  sssl_policy = "ELBSecurityPolicy-2016-08"
  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }
}

resource "aws_acm_certificate" "main" {
  domain_name       = aws_lb.main.dns_name 
  validation_method = "DNS"
  tags = {
    Name        = "${var.name}-ssl-cert-${var.environment}"
    Environment = var.environment
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_certificate" "main" {
  listener_arn    = aws_alb_listener.https.arn
  certificate_arn = aws_acm_certificate.main.arn
}




output "aws_alb_target_group_arn" {
  value = aws_alb_target_group.main.arn
}


