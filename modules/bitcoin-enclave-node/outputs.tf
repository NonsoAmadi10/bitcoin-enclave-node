output "instance_id" {
  description = "The ID of the EC2 instance hosting the enclave."
  value       = aws_instance.enclave_host.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = aws_instance.enclave_host.public_ip
}

# The attestation document is generated at runtime by the enclave and verified by the parent application.
# Terraform cannot directly output this dynamic value.
# output "attestation_document" {
#   description = "The cryptographic attestation document from the running enclave."
#   value       = "generated-at-runtime" 
# }

output "enclave_measurement" {
  description = "The expected PCR0 measurement of the enclave image that the system will verify against."
  value       = var.expected_measurement
}

# The endpoint for interacting with the enclave's parent application.
# This will depend on the application's configuration (e.g., specific port, DNS).
# output "endpoint" {
#   description = "The network endpoint for interacting with the enclave's proxy application."
#   value       = "configured-by-application"
# }