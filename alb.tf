# Security Group for ALB
resource "aws_security_group" "sttf_alb_sg" {
  name_prefix = "sttf-alb-"
  description = "Security group for STTF Application Load Balancer"
  vpc_id      = aws_vpc.sttf_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "sttf-alb-sg"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# Application Load Balancer for Production
resource "aws_lb" "sttf_prod_alb" {
  name               = "sttf-prod-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sttf_alb_sg.id]
  subnets            = [aws_subnet.sttf_public_subnet_1.id, aws_subnet.sttf_public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name        = "sttf-prod-alb"
    Environment = "production"
    Project     = "sttf-hosting"
  }
}

# Application Load Balancer for Staging
resource "aws_lb" "sttf_staging_alb" {
  name               = "sttf-staging-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sttf_alb_sg.id]
  subnets            = [aws_subnet.sttf_public_subnet_1.id, aws_subnet.sttf_public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name        = "sttf-staging-alb"
    Environment = "staging"
    Project     = "sttf-hosting"
  }
}

# Target Group for Staging
resource "aws_lb_target_group" "sttf_staging_tg" {
  name     = "sttf-staging-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.sttf_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "sttf-staging-tg"
    Environment = "staging"
    Project     = "sttf-hosting"
  }
}

# Target Group for Production
resource "aws_lb_target_group" "sttf_prod_tg" {
  name     = "sttf-prod-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.sttf_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "sttf-prod-tg"
    Environment = "production"
    Project     = "sttf-hosting"
  }
}

# Target Group Attachment for Staging
resource "aws_lb_target_group_attachment" "sttf_staging_tga" {
  target_group_arn = aws_lb_target_group.sttf_staging_tg.arn
  target_id        = aws_instance.sttf_api_staging.id
  port             = 5000
}

# Target Group Attachment for Production
resource "aws_lb_target_group_attachment" "sttf_prod_tga" {
  target_group_arn = aws_lb_target_group.sttf_prod_tg.arn
  target_id        = aws_instance.sttf_api_prod.id
  port             = 5000
}

# SSL Certificate (using AWS Certificate Manager) - Optional
resource "aws_acm_certificate" "sttf_cert" {
  count = var.domain_name != "" ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "sttf-ssl-cert"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# Certificate validation - Optional
resource "aws_acm_certificate_validation" "sttf_cert_validation" {
  count = var.domain_name != "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.sttf_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.sttf_cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# Route53 Hosted Zone (if it doesn't exist) - Optional
resource "aws_route53_zone" "sttf_zone" {
  count = var.create_route53_zone ? 1 : 0
  name  = var.domain_name

  tags = {
    Name        = "sttf-zone"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# Route53 Records for certificate validation - Optional
resource "aws_route53_record" "sttf_cert_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.sttf_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id != "" ? var.route53_zone_id : aws_route53_zone.sttf_zone[0].zone_id
}

# ALB Listener for Production HTTP
resource "aws_lb_listener" "sttf_prod_http_listener" {
  load_balancer_arn = aws_lb.sttf_prod_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sttf_prod_tg.arn
  }
}

# ALB Listener for Staging HTTP
resource "aws_lb_listener" "sttf_staging_http_listener" {
  load_balancer_arn = aws_lb.sttf_staging_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sttf_staging_tg.arn
  }
}

# ALB Listener for Production HTTPS (only if domain is provided)
resource "aws_lb_listener" "sttf_prod_https_listener" {
  count = var.domain_name != "" ? 1 : 0

  load_balancer_arn = aws_lb.sttf_prod_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.sttf_cert_validation[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sttf_prod_tg.arn
  }
}

# ALB Listener for Staging HTTPS (only if domain is provided)
resource "aws_lb_listener" "sttf_staging_https_listener" {
  count = var.domain_name != "" ? 1 : 0

  load_balancer_arn = aws_lb.sttf_staging_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.sttf_cert_validation[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sttf_staging_tg.arn
  }
}

# HTTP to HTTPS redirect for Production (only if domain is provided)
resource "aws_lb_listener_rule" "sttf_prod_http_redirect" {
  count = var.domain_name != "" ? 1 : 0

  listener_arn = aws_lb_listener.sttf_prod_http_listener.arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# HTTP to HTTPS redirect for Staging (only if domain is provided)
resource "aws_lb_listener_rule" "sttf_staging_http_redirect" {
  count = var.domain_name != "" ? 1 : 0

  listener_arn = aws_lb_listener.sttf_staging_http_listener.arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# Route53 A record for Production ALB (only if domain is provided)
resource "aws_route53_record" "sttf_prod_api" {
  count = var.domain_name != "" ? 1 : 0

  zone_id = var.route53_zone_id != "" ? var.route53_zone_id : aws_route53_zone.sttf_zone[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.sttf_prod_alb.dns_name
    zone_id                = aws_lb.sttf_prod_alb.zone_id
    evaluate_target_health = true
  }
}

# Route53 A record for Staging ALB (only if domain is provided)
resource "aws_route53_record" "sttf_staging_api" {
  count = var.domain_name != "" ? 1 : 0

  zone_id = var.route53_zone_id != "" ? var.route53_zone_id : aws_route53_zone.sttf_zone[0].zone_id
  name    = "staging.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.sttf_staging_alb.dns_name
    zone_id                = aws_lb.sttf_staging_alb.zone_id
    evaluate_target_health = true
  }
}
