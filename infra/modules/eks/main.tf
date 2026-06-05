
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.name}-eks"
  kubernetes_version = var.cluster_version

  addons = {
    vpc-cni = {
      before_compute = true
    }
    coredns    = {}
    kube-proxy = {}
  }

  dataplane_wait_duration = "60s"

  endpoint_public_access  = false
  endpoint_private_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  eks_managed_node_groups = {
    app = {
      instance_types = ["t3.small"]

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
      tags = {
        VpcEndpointsReady = sha1(join(",", var.vpc_endpoint_ids))
      }
    }
  }

  tags = var.tags
}
