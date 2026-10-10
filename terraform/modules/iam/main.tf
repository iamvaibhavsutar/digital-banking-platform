variable "name"        { type = string }
variable "ssm_prefix"  { type = string } # e.g. /banking/*

data "aws_caller_identity" "me" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ---- Kubernetes node role (kept TINY: Pods in some namespaces can reach it via IMDS) ----
resource "aws_iam_role" "node" {
  name               = "${var.name}-k8s-node"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}
resource "aws_iam_role_policy_attachment" "node_ecr_read" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "node_cw" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_role_policy" "node_params" {
  name = "read-banking-parameters"
  role = aws_iam_role.node.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"],
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.me.account_id}:parameter${var.ssm_prefix}" },
      { Effect = "Allow", Action = ["sns:Publish"], Resource = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.me.account_id}:${var.name}-alerts" }
    ]
  })
}
resource "aws_iam_instance_profile" "node" {
  name = "${var.name}-k8s-node"
  role = aws_iam_role.node.name
}

# ---- Tools host role (Jenkins builds/pushes images) ----
resource "aws_iam_role" "tools" {
  name               = "${var.name}-tools"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}
resource "aws_iam_role_policy_attachment" "tools_ssm" {
  role       = aws_iam_role.tools.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "tools_cw" {
  role       = aws_iam_role.tools.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_role_policy_attachment" "tools_ecr_power" {
  role       = aws_iam_role.tools.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
resource "aws_iam_role_policy" "tools_params" {
  name = "read-banking-parameters"
  role = aws_iam_role.tools.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"],
      Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.me.account_id}:parameter${var.ssm_prefix}" }]
  })
}
resource "aws_iam_instance_profile" "tools" {
  name = "${var.name}-tools"
  role = aws_iam_role.tools.name
}

output "node_profile_name"  { value = aws_iam_instance_profile.node.name }
output "tools_profile_name" { value = aws_iam_instance_profile.tools.name }
output "node_role_name"     { value = aws_iam_role.node.name }
