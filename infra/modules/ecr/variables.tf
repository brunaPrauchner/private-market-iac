variable "name" {
  description = "Name prefix for ECR resources."
  type        = string
}

variable "tags" {
  description = "Tags applied to ECR resources."
  type        = map(string)
}