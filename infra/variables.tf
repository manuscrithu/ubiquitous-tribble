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

variable "postgres_password" {
  description = "Password for the PostgreSQL database user."
  type        = string
  sensitive   = true
}

variable "postgres_user" {
  description = "Username used to authenticate with the PostgreSQL database."
  type        = string
}

variable "postgres_db" {
  description = "Name of the PostgreSQL database used by the application."
  type        = string
}

variable "secret_key" {
  description = "Secret key used by the application for cryptographic signing and security-related operations."
  type        = string
  sensitive   = true
}

variable "next_public_api_url" {
  description = "Public URL of the backend API used by the Next.js frontend."
  type        = string
}

variable "github_repository" {
  description = "URL or identifier of the GitHub repository containing the application source code."
  type        = string
}

variable "grafana_password" {
  description = "Password used to authenticate with the Grafana instance."
  type        = string
  sensitive   = true
}

variable "grafana_root_url" {
  description = "Public root URL used to access the Grafana instance."
  type        = string
}