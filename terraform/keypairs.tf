resource "digitalocean_ssh_key" "main" {
  name       = "bootstrap_ssh_key"
  public_key = "${file(var.public_key_path)}"
}
