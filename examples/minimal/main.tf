# This is an example of how to use the bitcoin-enclave-node module.

provider "aws" {
  region = "us-east-1" # Or your preferred region
}

module "enclave_node" {
  source = "../../modules/bitcoin-enclave-node"

  aws_region = "us-east-1"
  # In a real scenario, you would restrict this to your IP
  allowed_cidrs = ["0.0.0.0/0"] 
  
  # These would be populated with the actual image details
  # enclave_image_digest = "sha256:..." 
  # expected_measurement = "..."
}

output "instance_id" {
  description = "The ID of the EC2 instance hosting the enclave."
  value       = module.enclave_node.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = module.enclave_node.instance_public_ip
}

output "attestation_document" {
  description = "The cryptographic attestation document from the running enclave."
  value       = module.enclave_node.attestation_document
}
