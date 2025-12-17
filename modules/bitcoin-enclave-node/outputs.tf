output "instance_id" {
  description = "The ID of the EC2 instance hosting the enclave."
  value       = aws_instance.enclave_host.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = aws_instance.enclave_host.public_ip
}

output "attestation_document" {
  description = "The cryptographic attestation document from the running enclave. (Placeholder - will be implemented with the enclave application)"
  value       = "not-yet-implemented"
}

output "enclave_measurement" {
  description = "The PCR0 measurement of the running enclave image. (Placeholder - will be implemented with the enclave application)"
  value       = "not-yet-implemented"
}

output "endpoint" {
  description = "The network endpoint for interacting with the enclave's proxy application. (Placeholder)"
  value       = "not-yet-implemented"
}