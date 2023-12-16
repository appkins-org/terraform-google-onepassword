locals {
  vault_config = jsonencode(
    {
      default_lease_ttl = "168h",
      max_lease_ttl     = "720h",
      disable_mlock     = "true",
      listener = {
        tcp = {
          address     = "0.0.0.0:8080",
          tls_disable = "1"
        }
      }
    }
  )
  secret_name = var.credential_secret_name != "" ? var.credential_secret_name : "${var.name}-${lower(random_id.connect.hex)}-credentials"
}
