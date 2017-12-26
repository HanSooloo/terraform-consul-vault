output "consul_droplet_name" {
  value = ["${digitalocean_droplet.server_consul.*.name}"]
}

output "consul_droplet_ip" {
  value = ["${digitalocean_droplet.server_consul.*.ipv4_address}"]
}

output "consul_droplet_private_ip" {
  value = ["${digitalocean_droplet.server_consul.*.ipv4_address_private}"]
}

output "vault_droplet_name" {
  value = ["${digitalocean_droplet.server_vault.*.name}"]
}

output "vault_droplet_id" {
  value = ["${digitalocean_droplet.server_vault.*.id}"]
}

output "vault_droplet_ip" {
  value = ["${digitalocean_droplet.server_vault.*.ipv4_address}"]
}

output "vault_droplet_private_ip" {
  value = ["${digitalocean_droplet.server_vault.*.ipv4_address_private}"]
}
