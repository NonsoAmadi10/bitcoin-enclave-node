output "instance_id" {
  description = "The ID of the EC2 instance hosting the enclave."
  value       = module.bitcoin_enclave_node.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = module.bitcoin_enclave_node.instance_public_ip
}

output "enclave_measurement" {
  description = "The expected PCR0 measurement that runtime attestation validates against."
  value       = module.bitcoin_enclave_node.enclave_measurement
}
