locals {
  name = var.project_name

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "./modules/vpc"

  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  tags                 = local.tags
}

module "ecr" {
  source = "./modules/ecr"

  name = local.name
  tags = local.tags
}

module "ssm_runner" {
  source = "./modules/ssm-runner"

  name      = local.name
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.private_subnet_ids[0]
  tags      = local.tags
}

module "eks" {
  source = "./modules/eks"

  name                    = local.name
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  admin_security_group_id = module.ssm_runner.security_group_id
  cluster_version         = var.cluster_version
  node_min_size           = var.node_min_size
  node_max_size           = var.node_max_size
  node_desired_size       = var.node_desired_size
  tags                    = local.tags
}

resource "aws_eks_access_entry" "ssm_runner" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.ssm_runner.role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ssm_runner_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.ssm_runner.role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.ssm_runner]
}

resource "aws_eks_access_entry" "local_admin" {
  count = var.cluster_admin_principal_arn == null ? 0 : 1

  cluster_name  = module.eks.cluster_name
  principal_arn = var.cluster_admin_principal_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "local_admin" {
  count = var.cluster_admin_principal_arn == null ? 0 : 1

  cluster_name  = module.eks.cluster_name
  principal_arn = var.cluster_admin_principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.local_admin]
}

module "app" {
  source = "./modules/app"
  count  = var.deploy_app ? 1 : 0

  name  = "${local.name}-app"
  image = module.ecr.nginx_image

  depends_on = [module.eks]
}

module "observability" {
  source = "./modules/observability"

  name               = local.name
  cluster_name       = module.eks.cluster_name
  log_retention_days = var.log_retention_days
  tags               = local.tags
}
