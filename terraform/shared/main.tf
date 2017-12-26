variable "do_token" {
  description = "DigitalOcean API Token to use when executing API calls."
}

variable "do_instance_id_url" {
  description = "Introspection URL for instance ID in Digital Ocean."
  default     = "http://169.254.169.254/metadata/v1/id"
}

variable "do_instance_hostname_url" {
  description = "Introspection URL for instance hostname in Digital Ocean."
  default     = "http://169.254.169.254/metadata/v1/hostname"
}

variable "do_instance_private_ip_url" {
  description = "Introspection URL for instance private IP in Digital Ocean."
  default     = "http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address"
}
