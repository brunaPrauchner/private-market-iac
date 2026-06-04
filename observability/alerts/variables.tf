variable "environment" {
  type        = string
  description = "Target environment for resources"
  default     = "prod"
}

variable "notification_channel" {
  type        = string
  description = "Destination for alert notifications"
  default     = "@slack-sre-alerts-mock"
}

variable "application_deployment_name" {
  type        = string
  description = "Kubernetes deployment name for the main application"
  default     = "monolith"
}

variable "kubernetes_namespace" {
  type        = string
  description = "Kubernetes namespace for the main application"
  default     = "prod"
}
