# This is an example of how to use the bitcoin-enclave-node module.

provider "aws" {
  region = "us-east-1" # Or your preferred region that supports Nitro Enclaves
}

module "enclave_node" {
  source = "../../modules/bitcoin-enclave-node"

  aws_region = "us-east-1"
  
  # IMPORTANT: Replace this with the URL of a public git repository that has the 
  # same structure as the `enclave_app` in this project.
  git_repository_url = "https://github.com/path-to-your/bitcoin-enclave-app.git"


  
  # --- Attestation and Integrity ---
  #
  # WORKFLOW FOR `expected_measurement`:
  # 1. On your first deployment, leave this variable commented out or empty.
  # 2. After the instance is created, the EIF will be built by the `user_data` script.
  # 3. Check the EC2 instance's logs (e.g., via CloudWatch or SSH) for the line:
  #    "Actual EIF PCR0 Measurement: <some_hash_value>"
  # 4. Copy this hash value and paste it here for `expected_measurement`.
  # 5. On all subsequent deployments, Terraform will ensure the `user_data` script 
  #    verifies that the newly built EIF has this exact measurement. If it doesn't match,
  #    the setup will fail, protecting against unintended changes to the enclave image.
  expected_measurement = "your-eif-pcr0-measurement-hash-goes-here" # e.g., "9a8b..."
}

output "instance_id" {
  description = "The ID of the EC2 instance hosting the enclave."
  value       = module.enclave_node.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = module.enclave_node.instance_public_ip
}

output "expected_enclave_measurement" {
  description = "The expected PCR0 measurement of the enclave image that the system will verify against."
  value       = module.enclave_node.enclave_measurement
}

# The attestation document is generated at runtime and verified by the parent application.
# It is not directly accessible as a Terraform output.
# You can view it in the EC2 instance logs if needed for debugging.
output "attestation_document_info" {
  description = "Attestation documents are generated and verified at runtime on the EC2 instance."
  value       = "See EC2 instance logs for details."
}
