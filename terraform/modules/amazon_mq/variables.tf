# ==============================================================
# Amazon MQ Module — Input Variables
# ==============================================================

variable "project" {
  description = "Project name used for resource names and tags."
  type        = string
}

variable "env" {
  description = "Deployment environment used for resource names and tags."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the Amazon MQ security group is created."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the ACTIVE_STANDBY_MULTI_AZ broker. Requires exactly two subnets in different AZs."
  type        = list(string)
}

variable "eks_node_sg_id" {
  description = "Security group ID attached to EKS worker nodes. Allowed inbound to Amazon MQ on AMQPS 5671."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the Secrets Manager secret."
  type        = string
}

variable "engine_version" {
  description = "RabbitMQ engine version for Amazon MQ."
  type        = string
  default     = "3.13"
}

variable "host_instance_type" {
  description = "Amazon MQ broker instance type."
  type        = string
  default     = "mq.t3.micro"
}

variable "secret_recovery_window_days" {
  description = "Days Secrets Manager waits before permanently deleting the MQ secret. Use 0 for academic destroyability."
  type        = number
  default     = 0
}
