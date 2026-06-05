provider "aws" {
  region  = var.aws_region
  profile = "terraform-dev"
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = coalesce(var.kubernetes_api_host, module.eks.cluster_endpoint)
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
  tls_server_name        = var.kubernetes_tls_server_name
}
