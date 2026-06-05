
variable "name" {
  description = "Name prefix for EKS resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where EKS will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the EKS cluster and node group."
  type        = list(string)
}

variable "vpc_endpoint_ids" {
  description = "VPC endpoint IDs required before private worker nodes are created."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to EKS resources."
  type        = map(string)
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
}

variable "node_min_size" {
  description = "Minimum number of nodes in the managed node group."
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of nodes in the managed node group."
  type        = number
}

variable "node_desired_size" {
  description = "Desired number of nodes in the managed node group."
  type        = number
}
