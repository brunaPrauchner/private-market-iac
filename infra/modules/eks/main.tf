
resource "aws_iam_policy" "ecr_pull_through_cache" {
  name        = "${var.name}-ecr-pull-through-cache"
  description = "Allow worker nodes to import images through ECR pull-through cache."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchImportUpstreamImage",
          "ecr:CreateRepository"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

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

  security_group_additional_rules = var.admin_security_group_id == null ? {} : {
    ingress_admin_runner_443 = {
      description              = "Allow private SSM runner to reach the Kubernetes API."
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = var.admin_security_group_id
    }
  }

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
        ECRPullThroughCache          = aws_iam_policy.ecr_pull_through_cache.arn
      }
    }
  }

  tags = var.tags
}
