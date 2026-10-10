variable "name"     { type = string }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "azs"      { type = list(string) }
variable "nat_ami"  { type = string }

locals {
  public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  db_cidrs      = ["10.0.21.0/24", "10.0.22.0/24"]
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.name}-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false
  tags = { Name = "${var.name}-public-${count.index + 1}" }
}
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = { Name = "${var.name}-private-${count.index + 1}" }
}
resource "aws_subnet" "db" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.db_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = { Name = "${var.name}-db-${count.index + 1}" }
}

# ---- NAT instance (cheaper than NAT Gateway; documented trade-off) ----
resource "aws_security_group" "nat" {
  name_prefix = "${var.name}-nat-"
  vpc_id      = aws_vpc.this.id
  ingress {
    description = "all traffic from private subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.private_cidrs
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.name}-nat-sg" }
  lifecycle { create_before_destroy = true }
}

resource "aws_iam_role" "nat" {
  name = "${var.name}-nat"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "nat_ssm" {
  role       = aws_iam_role.nat.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "nat" {
  name = "${var.name}-nat"
  role = aws_iam_role.nat.name
}

resource "aws_instance" "nat" {
  ami                         = var.nat_ami
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.nat.id]
  iam_instance_profile        = aws_iam_instance_profile.nat.name
  associate_public_ip_address = true
  source_dest_check           = false # REQUIRED for NAT
  user_data = <<-EOT
    #!/bin/bash
    set -e
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-nat.conf
    sysctl -p /etc/sysctl.d/99-nat.conf
    IFACE=$(ip -o -4 route show to default | awk '{print $5}')
    DEBIAN_FRONTEND=noninteractive apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
    iptables -t nat -A POSTROUTING -o "$IFACE" -s ${var.vpc_cidr} -j MASQUERADE
    iptables -A FORWARD -s ${var.vpc_cidr} -j ACCEPT
    iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
    netfilter-persistent save
  EOT
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
  root_block_device {
    volume_size = 8
    encrypted   = true
  }
  tags = { Name = "${var.name}-nat" }
}

# ---- route tables ----
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.name}-rt-public" }
}
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }
  tags = { Name = "${var.name}-rt-private" }
}
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# DB subnets: local route only, NO default route
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-rt-db" }
}
resource "aws_route_table_association" "db" {
  count          = 2
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

# ---- NACL for the DB tier (stateless: return traffic needs its own rule) ----
resource "aws_network_acl" "db" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.db[*].id
  tags       = { Name = "${var.name}-nacl-db" }

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = local.private_cidrs[0]
    from_port  = 5432
    to_port    = 5432
  }
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = local.private_cidrs[1]
    from_port  = 5432
    to_port    = 5432
  }
  # replies to the app subnets (ephemeral ports) - Lab 3 deletes rule 100
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = local.private_cidrs[0]
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = local.private_cidrs[1]
    from_port  = 1024
    to_port    = 65535
  }
}

output "vpc_id"             { value = aws_vpc.this.id }
output "public_subnet_ids"  { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
output "db_subnet_ids"      { value = aws_subnet.db[*].id }
output "nat_instance_id"    { value = aws_instance.nat.id }
output "private_route_table_id" { value = aws_route_table.private.id }
output "vpc_cidr"           { value = aws_vpc.this.cidr_block }
