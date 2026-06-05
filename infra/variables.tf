
variable "aws_region" {
  description = "AWS region where resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix used for resources."
  type        = string
  default     = "private-market-iac"
}

variable "environment" {
  description = "Environment name used for tagging."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "Availability zones used for private subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.33"
}

variable "node_min_size" {
  description = "Minimum number of nodes in the managed node group."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes in the managed node group."
  type        = number
  default     = 1
}

variable "node_desired_size" {
  description = "Desired number of nodes in the managed node group."
  type        = number
  default     = 1
}

variable "deploy_app" {
  description = "Whether to deploy Kubernetes app resources. Enable this from a host that can reach the private EKS API."
  type        = bool
  default     = false
}

variable "kubernetes_api_host" {
  description = "Optional Kubernetes API host override, used when accessing the private EKS API through an SSM tunnel."
  type        = string
  default     = null
}

variable "kubernetes_tls_server_name" {
  description = "Optional TLS server name for the Kubernetes API, used when tunneling the private EKS endpoint locally."
  type        = string
  default     = null
}

variable "cluster_admin_principal_arn" {
  description = "Optional IAM principal ARN to grant EKS cluster-admin access for local Terraform or kubectl use."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Retention period for CloudWatch log groups."
  type        = number
  default     = 7
}
