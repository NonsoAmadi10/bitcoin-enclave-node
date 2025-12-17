locals {
  enclave_name       = "${var.name_prefix}-enclave"
  # Assuming the EIF will be built from the cloned repo and placed here
  enclave_image_path = "/home/ec2-user/app/enclave.eif" 
  # Arbitrary CID for VSOCK communication, typically 3 or greater
  enclave_cid        = 3 
}