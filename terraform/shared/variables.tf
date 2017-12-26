variable "region" {
  description = "Region in which an instance should be launched"
}

variable "size" {
  description = "Slug size to use for the Digital Ocean droplet"
}

variable "image" {
  description = "Slug name to use for the Digital Ocean droplet"
}

variable "consul_servers" {
  description = "The number of consul servers."
}

variable "consul_version" {
  description = "Consul version to install."
}

variable "consul_service" {
  description = "The service account for Consul."
  default     = "consul"
}

variable "consul_encryption_key" {
  description = "Encryption key used to encrypt Consul traffic"
}

variable "vault_servers" {
  description = "The number of Vault servers."
}

variable "vault_version" {
  description = "Vault version to install."
}

variable "vault_service" {
  description = "The service account for Vault."
  default     = "vault"
}

variable "ssl_pki_dir" {
  description = "Directory where cert keys are kept."
}

variable "ssl_bin_dir" {
  description = "Directory where shell scripts are kept."
}
