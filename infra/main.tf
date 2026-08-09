terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# ── Networking ────────────────────────────────────────────────────────────────

resource "oci_core_vcn" "shortener_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = "10.0.0.0/16"
  display_name   = "shortener-vcn"
  dns_label      = "shortener"
}

resource "oci_core_internet_gateway" "shortener_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.shortener_vcn.id
  display_name   = "shortener-igw"
  enabled        = true
}

resource "oci_core_route_table" "shortener_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.shortener_vcn.id
  display_name   = "shortener-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.shortener_igw.id
  }
}

resource "oci_core_security_list" "shortener_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.shortener_vcn.id
  display_name   = "shortener-sl"

  # Allow all outbound traffic
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH — needed for Phase 3 (manual config) and Phase 5 (GitHub Actions deploy)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP — Nginx will listen here (Phase 4)
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS — Certbot/Let's Encrypt (Phase 4)
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_subnet" "shortener_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.shortener_vcn.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "shortener-public-subnet"
  dns_label         = "public"
  route_table_id    = oci_core_route_table.shortener_rt.id
  security_list_ids = [oci_core_security_list.shortener_sl.id]

  # Public subnet — instances get a public IP automatically
  prohibit_public_ip_on_vnic = false
}

# ── Compute ───────────────────────────────────────────────────────────────────

resource "oci_core_instance" "shortener_vm" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = "shortener-vm"
  shape               = "VM.Standard.E2.1.Micro"  # Always-free eligible

  source_details {
    source_type = "image"
    source_id   = var.vm_image_ocid
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.shortener_subnet.id
    assign_public_ip = true
    display_name     = "shortener-vnic"
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.ssh_public_key_path))
  }

  # Prevent accidental destruction of the VM
  lifecycle {
    prevent_destroy = false  # Set to true once the VM is your long-lived server
  }
}

resource "oci_identity_dynamic_group" "shortener_vm_dg" {
  compartment_id = var.tenancy_ocid   # dynamic groups are tenancy-level
  name           = "shortener-vm-dynamic-group"
  description    = "Matches the shortener VM instance"
  matching_rule  = "ANY {instance.id = '${oci_core_instance.shortener_vm.id}'}"
}

resource "oci_identity_policy" "shortener_vm_vault_policy" {
  compartment_id = var.compartment_ocid
  name           = "shortener-vm-vault-policy"
  description    = "Allow shortener VM to read its own secrets"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.shortener_vm_dg.name} to read secret-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.shortener_vm_dg.name} to manage objects in compartment id ${var.compartment_ocid} where target.bucket.name = 'shortener-db-backups'"
  ]
}

resource "oci_objectstorage_bucket" "backups" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "shortener-db-backups"
  storage_tier   = "Standard"
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}
