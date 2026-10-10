variable "name"              { type = string }
variable "db_subnet_ids"     { type = list(string) }
variable "security_group_id" { type = string }
variable "multi_az" {
  type    = bool
  default = false
}
variable "ssm_password_path" { type = string } # e.g. /banking/bank-dev/db/password

resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name  = var.ssm_password_path
  type  = "SecureString"
  value = random_password.db.result
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.db_subnet_ids
}

resource "aws_db_instance" "this" {
  identifier              = "${var.name}-postgres"
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  storage_encrypted       = true
  db_name                 = "bankdb"
  username                = "bank"
  password                = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [var.security_group_id]
  publicly_accessible     = false
  multi_az                = var.multi_az
  backup_retention_period = 7
  skip_final_snapshot     = true # lab only; production: false + final_snapshot_identifier
  deletion_protection     = false
  apply_immediately       = true
}

output "identifier" { value = aws_db_instance.this.identifier }
output "endpoint"   { value = aws_db_instance.this.address }
