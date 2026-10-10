variable "name"              { type = string }
variable "vpc_id"            { type = string }
variable "subnet_ids"        { type = list(string) }
variable "security_group_id" { type = string }
variable "target_instance_ids" { type = list(string) }
variable "certificate_arn" {
  type    = string
  default = ""
}

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [var.security_group_id]
  tags               = { Name = "${var.name}-alb" }
}

resource "aws_lb_target_group" "ingress" {
  name        = "${var.name}-traefik"
  port        = 30080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    path                = "/ping"   # Traefik ping entrypoint, see deploy/traefik-values.yaml
    port                = "30080"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  deregistration_delay = 30
}

resource "aws_lb_target_group_attachment" "workers" {
  count            = length(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.ingress.arn
  target_id        = var.target_instance_ids[count.index]
  port             = 30080
}

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn == "" ? 0 : 1
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  dynamic "default_action" {
    for_each = var.certificate_arn == "" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.ingress.arn
    }
  }
  dynamic "default_action" {
    for_each = var.certificate_arn != "" ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

output "dns_name"        { value = aws_lb.this.dns_name }
output "zone_id"         { value = aws_lb.this.zone_id }
output "arn_suffix"      { value = aws_lb.this.arn_suffix }
output "tg_arn_suffix"   { value = aws_lb_target_group.ingress.arn_suffix }
