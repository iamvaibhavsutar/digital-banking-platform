output "alb_dns_name"   { value = module.alb.dns_name }
output "rds_endpoint"   { value = module.rds.endpoint }
output "ecr_urls"       { value = module.ecr.repository_urls }
output "node_ips"       { value = module.k8s_nodes.private_ips }
output "tools_ip"       { value = module.tools.private_ips }
output "sns_topic_arn"  { value = module.monitoring.sns_topic_arn }
output "ssm_connect_cp" { value = "aws ssm start-session --target ${module.k8s_nodes.instance_ids["kube-cp"]} --profile ${var.aws_profile} --region ${var.region}" }
