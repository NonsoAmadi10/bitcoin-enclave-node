variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "name_prefix" {
  description = "A prefix used for all created resources to ensure unique names."
  type        = string
  default     = "btc-enclave"
}

variable "git_repository_url" {
  description = "The URL of the git repository to clone onto the instance."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type for the enclave host. Must be a Nitro Enclaves compatible instance."
  type        = string
  default     = "m5.xlarge"
}



variable "enclave_image_digest" {
  description = "The digest of the enclave image to be deployed. Used for verification."
  type        = string
  default     = "" # This will be set in the example
}

variable "expected_measurement" {
  description = "The expected PCR0 measurement of the enclave image."
  type        = string
  default     = "" # This will be set in the example
}

variable "kms_key_arn" {
  description = "Optional: The ARN of the KMS key to use for secret unwrapping within the enclave."
  type        = string
  default     = null
}

variable "log_sink" {
  description = "Optional: The destination for logs (e.g., CloudWatch Log Group ARN)."
  type        = string
  default     = null
}

variable "enclave_cpu_count" {
  description = "The number of vCPUs to allocate to the Nitro Enclave."
  type        = number
  default     = 1
}

variable "enclave_memory_mib" {
  description = "The amount of memory (in MiB) to allocate to the Nitro Enclave."
  type        = number
  default     = 256
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy the enclave host in. If not provided, the default VPC will be used."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The ID of the subnet to deploy the enclave host in. If not provided, a default subnet in the selected VPC will be used."
  type        = string
  default     = null
}