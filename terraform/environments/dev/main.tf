locals {
  name = "bank-${var.env}"
  azs  = ["${var.region}a", "${var.region}b"]
}

data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

module "vpc" {
  source  = "../../modules/vpc"
  name    = local.name
  azs     = local.azs
  nat_ami = data.aws_ssm_parameter.ubuntu.value
}

module "security" {
  source   = "../../modules/security"
  name     = local.name
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr
}

module "iam" {
  source     = "../../modules/iam"
  name       = local.name
  ssm_prefix = "/banking/*"
}

module "ecr" {
  source       = "../../modules/ecr"
  repositories = var.services
}

# ---- Kubernetes nodes: 1 control plane + 3 workers across both AZs ----
module "k8s_nodes" {
  source = "../../modules/ec2"
  name   = local.name
  instances = {
    "kube-cp"      = { subnet_id = module.vpc.private_subnet_ids[0], instance_type = var.cp_instance_type, volume_gb = 30, role = "cp" }
    "kube-worker1" = { subnet_id = module.vpc.private_subnet_ids[0], instance_type = var.worker_instance_type, volume_gb = 30, role = "worker" }
    "kube-worker2" = { subnet_id = module.vpc.private_subnet_ids[1], instance_type = var.worker_instance_type, volume_gb = 30, role = "worker" }
    "kube-worker3" = { subnet_id = module.vpc.private_subnet_ids[1], instance_type = var.worker_instance_type, volume_gb = 30, role = "worker" }
  }
  security_group_ids = [module.security.nodes_sg_id]
  instance_profile   = module.iam.node_profile_name
  user_data          = file("${path.module}/../../../deploy/bootstrap/node-prep.sh")
}

# ---- Tools host: Jenkins, SonarQube, Elasticsearch/Kibana ----
module "tools" {
  source = "../../modules/ec2"
  name   = local.name
  instances = {
    "tools" = { subnet_id = module.vpc.private_subnet_ids[0], instance_type = var.tools_instance_type, volume_gb = 100, role = "tools" }
  }
  security_group_ids = [module.security.tools_sg_id]
  instance_profile   = module.iam.tools_profile_name
  user_data          = file("${path.module}/../../../deploy/bootstrap/tools-prep.sh")
}

module "rds" {
  source            = "../../modules/rds"
  name              = local.name
  db_subnet_ids     = module.vpc.db_subnet_ids
  security_group_id = module.security.rds_sg_id
  ssm_password_path = "/banking/${local.name}/db/password"
}

module "alb" {
  source              = "../../modules/alb"
  name                = local.name
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_id   = module.security.alb_sg_id
  target_instance_ids = [for k, v in module.k8s_nodes.instance_ids : v if startswith(k, "kube-worker")]
  certificate_arn     = var.domain_name == "" ? var.certificate_arn : module.dns[0].certificate_arn
}

module "dns" {
  count        = var.domain_name == "" ? 0 : 1
  source       = "../../modules/dns"
  domain_name  = var.domain_name
  alb_dns_name = module.alb.dns_name
  alb_zone_id  = module.alb.zone_id
}

module "monitoring" {
  source             = "../../modules/monitoring"
  name               = local.name
  alert_email        = var.alert_email
  instance_ids       = merge(module.k8s_nodes.instance_ids, module.tools.instance_ids)
  alb_arn_suffix     = module.alb.arn_suffix
  tg_arn_suffix      = module.alb.tg_arn_suffix
  rds_id             = module.rds.identifier
  monthly_budget_usd = var.monthly_budget_usd
}

module "scheduler" {
  source       = "../../modules/scheduler"
  name         = local.name
  instance_ids = concat(values(module.k8s_nodes.instance_ids), values(module.tools.instance_ids), [module.vpc.nat_instance_id])
  rds_id       = module.rds.identifier
}
