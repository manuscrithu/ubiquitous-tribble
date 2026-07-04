variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of your OCI user"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the API signing key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API private key PEM file"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "OCI region identifier (e.g. ap-mumbai-1)"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain name (from OCI Console)"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID of the compartment to deploy into (use tenancy OCID for root)"
  type        = string
}

variable "vm_image_ocid" {
  description = "OCID of the Ubuntu 22.04 platform image for your region"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key to inject into the VM"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}