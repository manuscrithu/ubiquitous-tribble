resource "oci_kms_vault" "shortener_vault" {
  compartment_id = var.compartment_ocid
  display_name   = "shortener-vault"
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "shortener_key" {
  compartment_id      = var.compartment_ocid
  display_name        = "shortener-secrets-key"
  management_endpoint = oci_kms_vault.shortener_vault.management_endpoint
  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

resource "oci_vault_secret" "postgres_password" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.shortener_vault.id
  key_id         = oci_kms_key.shortener_key.id
  secret_name    = "shortener-postgres-password-v2"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.postgres_password)
  }
}

resource "oci_vault_secret" "postgres_user" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.shortener_vault.id
  key_id         = oci_kms_key.shortener_key.id
  secret_name    = "shortener-postgres-user"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.postgres_user)
  }
}

resource "oci_vault_secret" "postgres_db" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.shortener_vault.id
  key_id         = oci_kms_key.shortener_key.id
  secret_name    = "shortener-postgres-db"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.postgres_db)
  }
}

resource "oci_vault_secret" "secret_key" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.shortener_vault.id
  key_id         = oci_kms_key.shortener_key.id
  secret_name    = "shortener-secret-key"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_key)
  }
}

resource "oci_vault_secret" "next_public_api_url" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.shortener_vault.id
  key_id         = oci_kms_key.shortener_key.id
  secret_name    = "shortener-next-public-api-url"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.next_public_api_url)
  }
}

resource "oci_vault_secret" "github_repository" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.shortener_vault.id
  key_id         = oci_kms_key.shortener_key.id
  secret_name    = "shortener-github-repository"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.github_repository)
  }
}

resource "oci_vault_secret" "grafana_password" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.shortener_vault.id
  key_id         = oci_kms_key.shortener_key.id
  secret_name    = "shortener-grafana-password"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.grafana_password)
  }
}

resource "oci_vault_secret" "grafana_root_url" {
  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.shortener_vault.id
  key_id         = oci_kms_key.shortener_key.id
  secret_name    = "shortener-grafana-root-url"
  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.grafana_root_url)
  }
}