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