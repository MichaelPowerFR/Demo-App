module "vpc" {
  source                 = "./modules/vpc/"
  name                   = "${var.resource_name_prefix}-vault"
  cidr                   = var.vpc_cidr
  azs                    = var.azs
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  private_subnets        = var.private_subnet_cidrs
  public_subnets         = var.public_subnet_cidrs
  private_subnet_tags    = var.private_subnet_tags

  tags = var.common_tags
}

module "secrets" {
  source = "./modules/secrets/"

  resource_name_prefix = var.resource_name_prefix
}

data "aws_region" "current" {}

module "iam" {
  source = "./modules/iam"

  aws_region                  = data.aws_region.current.name
  kms_key_arn                 = module.kms.kms_key_arn
  resource_name_prefix        = var.resource_name_prefix
  secrets_manager_arn         = module.secrets.secrets_manager_arn
  user_supplied_iam_role_name = var.user_supplied_iam_role_name
}

module "kms" {
  source = "./modules/kms"

  common_tags               = var.common_tags
  kms_key_deletion_window   = var.kms_key_deletion_window
  resource_name_prefix      = var.resource_name_prefix
  user_supplied_kms_key_arn = var.user_supplied_kms_key_arn
}

module "user_data" {
  source = "./modules/user_data"

  aws_region                  = data.aws_region.current.name
  kms_key_arn                 = module.kms.kms_key_arn
  leader_tls_servername       = var.leader_tls_servername
  resource_name_prefix        = var.resource_name_prefix
  secrets_manager_arn         = module.secrets.secrets_manager_arn
  user_supplied_userdata_path = var.user_supplied_userdata_path
  vault_version               = var.vault_version
}

module "loadbalancer" {
  depends_on = [module.vpc]
  source     = "./modules/load_balancer"

  allowed_inbound_cidrs = var.allowed_inbound_cidrs_lb
  common_tags           = var.common_tags
  lb_certificate_arn    = module.secrets.lb_certificate_arn
  lb_health_check_path  = var.lb_health_check_path
  lb_subnets            = module.vpc.private_subnets
  lb_type               = var.lb_type
  resource_name_prefix  = var.resource_name_prefix
  ssl_policy            = var.ssl_policy
  vault_sg_id           = module.vm.vault_sg_id
  vpc_id                = module.vpc.vpc_id
}


module "vm" {
  depends_on = [module.vpc]

  source = "./modules/vm"

  allowed_inbound_cidrs     = var.allowed_inbound_cidrs_lb
  allowed_inbound_cidrs_ssh = var.allowed_inbound_cidrs_ssh
  aws_iam_instance_profile  = module.iam.aws_iam_instance_profile
  common_tags               = var.common_tags
  instance_type             = var.instance_type
  key_name                  = var.key_name
  lb_type                   = var.lb_type
  node_count                = var.node_count
  resource_name_prefix      = var.resource_name_prefix
  userdata_script           = module.user_data.vault_userdata_base64_encoded
  user_supplied_ami_id      = local.vault_server_ami_id
  vault_lb_sg_id            = module.loadbalancer.vault_lb_sg_id
  subnet_cidr_blocks        = module.vpc.private_subnets_cidr_blocks
  subnet_ids                = module.vpc.private_subnets
  vault_target_group_arn    = module.loadbalancer.vault_target_group_arn
  vpc_id                    = module.vpc.vpc_id
}

resource "aws_security_group_rule" "vault_connection_from_bastion" {
  description              = "Incoming ssh from bastion"
  type                     = "ingress"
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.bastion_host_security_group.id

  security_group_id = module.loadbalancer.vault_lb_sg_id
}

resource "aws_security_group_rule" "vault_connection_from_client" {
  description              = "Incoming Vault Request from Client"
  type                     = "ingress"
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.client_security_group.id

  security_group_id = module.loadbalancer.vault_lb_sg_id
}
