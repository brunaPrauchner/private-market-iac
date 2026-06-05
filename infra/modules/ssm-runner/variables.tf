variable "name" {
  description = "Name prefix for SSM runner resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the SSM runner."
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID for the SSM runner."
  type        = string
}

variable "instance_type" {
  description = "Instance type for the SSM runner."
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Tags applied to SSM runner resources."
  type        = map(string)
}
