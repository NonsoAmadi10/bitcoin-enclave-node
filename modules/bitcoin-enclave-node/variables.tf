variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type for the enclave host. Must be a Nitro Enclaves compatible instance."
  type        = string
  default     = "m5.xlarge"
}

variable "allowed_cidrs" {
  description = "A list of CIDR blocks to allow SSH access from."
  type        = list(string)
  default     = ["0.0.0.0/0"]
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