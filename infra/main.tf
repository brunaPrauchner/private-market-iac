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

module "eks" {
  source = "./modules/eks"

  name               = local.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_endpoint_ids   = module.vpc.vpc_endpoint_ids
  cluster_version    = var.cluster_version
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  node_desired_size  = var.node_desired_size
  tags               = local.tags
}
