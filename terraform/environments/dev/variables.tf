variable "region" { default = "ap-south-1" }
variable "aws_profile" { default = "bank" }
variable "env" { default = "dev" }
variable "alert_email" { type = string }
variable "monthly_budget_usd" { default = 60 }
variable "worker_instance_type" { default = "t3a.medium" }
variable "tools_instance_type" { default = "t3a.xlarge" }
variable "cp_instance_type" { default = "t3a.medium" }
variable "certificate_arn" {
  type    = string
  default = ""
}
variable "domain_name" {
  type        = string
  default     = "" # set to enable the dns module (Route 53 + ACM)
  description = "e.g. yourdomain.in"
}
variable "services" {
  type = list(string)
  default = ["auth-service", "account-service", "transfer-service", "transaction-service", "notification-service", "portal"]
}
