variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "name_prefix" {
  description = "A prefix used for created resources."
  type        = string
  default     = "btc-enclave"
}

variable "git_repository_url" {
  description = "Git repository URL cloned to the host during bootstrap."
  type        = string
}

variable "instance_type" {
  description = "Nitro-compatible EC2 instance type used as the enclave parent."
  type        = string
  default     = "m5.xlarge"
}

variable "enclave_image_digest" {
  description = "Optional image digest metadata for release traceability."
  type        = string
  default     = ""
}

variable "expected_measurement" {
  description = "Expected PCR0 measurement used to verify enclave image integrity."
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN used for enclave secret unwrapping flows."
  type        = string
  default     = null
}

variable "log_sink" {
  description = "Optional log destination metadata (for example, CloudWatch log group ARN)."
  type        = string
  default     = null
}

variable "enclave_cpu_count" {
  description = "vCPU count allocated to the enclave."
  type        = number
  default     = 1
}

variable "enclave_memory_mib" {
  description = "Memory in MiB allocated to the enclave."
  type        = number
  default     = 256
}

variable "vpc_id" {
  description = "Optional VPC ID for deployment. Uses default VPC when null."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Optional subnet ID for deployment. Uses a subnet in selected VPC when null."
  type        = string
  default     = null
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to the host. Empty list disables SSH ingress."
  type        = list(string)
  default     = []
}
