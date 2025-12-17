# This file is intentionally left mostly empty.
#
# The module is designed to consume existing VPC and subnet IDs from the user
# via the `vpc_id` and `subnet_id` variables. If these are not provided,
# the module attempts to use the AWS default VPC and a default subnet within it.
#
# This approach keeps the module focused on the core Nitro Enclaves deployment
# and avoids opinionated network infrastructure creation (e.g., specific VPC,
# NAT Gateways, Internet Gateways, etc.), allowing for greater flexibility
# in integrating with existing network architectures.
#
# Network security (Security Groups) is defined in `security.tf`.
