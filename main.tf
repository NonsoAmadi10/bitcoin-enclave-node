module "bitcoin_enclave_node" {
  source = "./modules/bitcoin-enclave-node"

  aws_region           = var.aws_region
  name_prefix          = var.name_prefix
  git_repository_url   = var.git_repository_url
  instance_type        = var.instance_type
  enclave_image_digest = var.enclave_image_digest
  expected_measurement = var.expected_measurement
  kms_key_arn          = var.kms_key_arn
  log_sink             = var.log_sink
  enclave_cpu_count    = var.enclave_cpu_count
  enclave_memory_mib   = var.enclave_memory_mib
  vpc_id               = var.vpc_id
  subnet_id            = var.subnet_id
  allowed_cidrs        = var.allowed_cidrs
}
