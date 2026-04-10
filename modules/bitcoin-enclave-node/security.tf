data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "enclave_node_sg" {
  name        = "${var.name_prefix}-sg"
  description = "Security group for enclave host"
  vpc_id      = var.vpc_id == null ? data.aws_vpc.default.id : var.vpc_id

  dynamic "ingress" {
    for_each = toset(var.allowed_cidrs)
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "SSH access"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
