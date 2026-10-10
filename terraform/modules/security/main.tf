variable "name"     { type = string }
variable "vpc_id"   { type = string }
variable "vpc_cidr" { type = string }

resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-alb" }
  lifecycle { create_before_destroy = true }
}
resource "aws_security_group" "nodes" {
  name_prefix = "${var.name}-nodes-"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-nodes" }
  lifecycle { create_before_destroy = true }
}
resource "aws_security_group" "tools" {
  name_prefix = "${var.name}-tools-"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-tools" }
  lifecycle { create_before_destroy = true }
}
resource "aws_security_group" "rds" {
  name_prefix = "${var.name}-rds-"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-rds" }
  lifecycle { create_before_destroy = true }
}

# ALB: HTTP/HTTPS from the internet
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
resource "aws_vpc_security_group_egress_rule" "alb_to_nodes" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 30080
  to_port                      = 30080
}

# Nodes: ALB -> Traefik NodePort, node<->node (all), tools -> nodes (kubectl 6443, prometheus scrape)
resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 30080
  to_port                      = 30080
}
resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "-1"
}
resource "aws_vpc_security_group_ingress_rule" "nodes_from_tools" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.tools.id
  ip_protocol                  = "-1"
}
resource "aws_vpc_security_group_egress_rule" "nodes_all" {
  security_group_id = aws_security_group.nodes.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Tools host
resource "aws_vpc_security_group_ingress_rule" "tools_from_nodes_es" {
  security_group_id            = aws_security_group.tools.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 9200
  to_port                      = 9200
}
resource "aws_vpc_security_group_ingress_rule" "tools_from_nodes_jenkins" {
  security_group_id            = aws_security_group.tools.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}
resource "aws_vpc_security_group_ingress_rule" "tools_from_alb_jenkins" {
  security_group_id            = aws_security_group.tools.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}
resource "aws_vpc_security_group_egress_rule" "tools_all" {
  security_group_id = aws_security_group.tools.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# RDS: only nodes and tools on 5432 (names match Labs 2 and 15)
resource "aws_vpc_security_group_ingress_rule" "rds_from_nodes" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}
resource "aws_vpc_security_group_ingress_rule" "rds_from_tools" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.tools.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

output "alb_sg_id"   { value = aws_security_group.alb.id }
output "nodes_sg_id" { value = aws_security_group.nodes.id }
output "tools_sg_id" { value = aws_security_group.tools.id }
output "rds_sg_id"   { value = aws_security_group.rds.id }
