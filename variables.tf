variable "name" {
  description = "Application name."
  type        = string
  default     = "connect"
  nullable    = false
}

variable "custom_domain" {
  type        = string
  description = "Custom domain name to use for the vault server. Leave blank to use the default domain name."
  default     = ""
  nullable    = false
}

variable "location" {
  description = "Google location where resources are to be created."
  type        = string
  default     = "us-central1"
}

variable "project" {
  description = "Google project ID."
  type        = string
}

variable "max_instance_count" {
  description = "Max number of container instances."
  type        = number
  default     = 1
}

variable "max_concurrency" {
  description = "Max number of connections per container instance."
  type        = number
  default     = 80 # Max per Cloud Run Documentation
}

variable "vpc_connector" {
  description = "Serverless VPC access connector."
  type        = string
  default     = ""
}

variable "service_account_id" {
  description = "ID for the service account to be used. This is the part of the service account email before the `@` symbol."
  type        = string
  default     = "connect-sa"
}

variable "credential_secret_name" {
  description = "Name of the secret in Secret Manager that contains the credentials for the vault server."
  type        = string
  default     = ""
  nullable    = false
}

variable "credential_data" {
  description = "Credential Data"
  type        = any
  default     = null

  validation {
    condition     = var.credential_data != null ? can(jsonencode(var.credential_data)) : true
    error_message = "Credential data must be a valid credential object."
  }
}

variable "credentials_base64" {
  description = "Credential Data"
  type        = string
  default     = null

  validation {
    condition     = var.credentials_base64 != null ? can(base64decode(var.credentials_base64)) : true
    error_message = "Credential data must be base64 encoded."
  }
}
