variable "name" {
  description = "Name used for Kubernetes app resources."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the application."
  type        = string
  default     = "app"
}

variable "image" {
  description = "Container image to deploy."
  type        = string
}

variable "replicas" {
  description = "Number of application replicas."
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Port exposed by the container."
  type        = number
  default     = 80
}

variable "service_port" {
  description = "ClusterIP service port."
  type        = number
  default     = 80
}
