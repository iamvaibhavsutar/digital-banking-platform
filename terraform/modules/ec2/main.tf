variable "name" { type = string }
variable "instances" {
  description = "map: key => { subnet_id, instance_type, volume_gb, role }"
  type = map(object({
    subnet_id     = string
    instance_type = string
    volume_gb     = number
    role          = string # "cp" | "worker" | "tools"
  }))
}
variable "security_group_ids" { type = list(string) }
variable "instance_profile"   { type = string }
variable "user_data"          { type = string }

data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

resource "aws_instance" "this" {
  for_each               = var.instances
  ami                    = data.aws_ssm_parameter.ubuntu.value
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.instance_profile
  user_data              = replace(var.user_data, "__ROLE__", each.value.role)

  metadata_options {
    http_tokens                 = "required" # IMDSv2
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2          # containers on the node still need IMDS (credential provider)
  }
  root_block_device {
    volume_size = each.value.volume_gb
    volume_type = "gp3"
    encrypted   = true
  }
  tags = {
    Name = "${var.name}-${each.key}"
    Role = each.value.role
  }
  lifecycle { ignore_changes = [ami, user_data] } # AMI/user_data changes must not replace running nodes
}

output "instance_ids" { value = { for k, v in aws_instance.this : k => v.id } }
output "private_ips"  { value = { for k, v in aws_instance.this : k => v.private_ip } }
