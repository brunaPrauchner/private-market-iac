output "namespace" {
  description = "Namespace where the app is deployed."
  value       = kubernetes_namespace.this.metadata[0].name
}

output "service_name" {
  description = "Name of the private ClusterIP service."
  value       = kubernetes_service.this.metadata[0].name
}

output "image" {
  description = "Container image deployed by the app."
  value       = var.image
}
