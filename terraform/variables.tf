# Digital Ocean slug creation parameters
#
variable "region" {
  description = "Region in which an instance should be launched"
}

variable "image" {
  description = "Slug name to use for the Digital Ocean droplet"
  default     = "ubuntu-16-04-x64"
}

variable "size" {
  description = "Slug size to use for the Digital Ocean droplet"
  default     = "512mb"
}

#############################
# CONSUL
#############################

variable "consul_version" {
  description = "Consul version to install"
}

variable "consul_servers" {
  description = "The number of Consul servers."
}

variable "consul_service" {
  description = "The service account for Consul."
  default     = "consul"
}

variable "consul_join_tag_key" {
  description = "Tag to use for consul auto-join"
}

variable "consul_join_tag_value" {
  description = "Value to search for in auto-join tag to use for consul auto-join"
}

variable "consul_encryption_key" {
  description = "Encryption key used to encrypt Consul traffic"
}

#############################
# VAULT
#############################
variable "vault_version" {
  description = "Vault version to install"
}

variable "vault_servers" {
  description = "The number of Vault servers."
}

variable "vault_service" {
  description = "The service account for Vault."
  default     = "vault"
}

#############################
# NOMAD
#############################
variable "nomad_version" {
  description = "Nomad version to install"
}

variable "nomad_servers" {
  description = "The number of Nomad servers."
}

variable "nomad_agents" {
  description = "The number of nomad agents"
}

#############################
# Keys and Secrets
#############################

variable "public_key_path" {
  description = "The absolute path on disk to the SSH public key."
}

variable "private_key_path" {
  description = "The absolute path on disk to the SSH private key."
}

variable "do_token" {
  description = "DigitalOcean API Token to use when executing API calls."
}

# Locals
locals {
  ssl_pki_dir = "${path.module}/../ssl/pki"
  ssl_bin_dir = "${path.module}/../ssl/bin"
}

#

