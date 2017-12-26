provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_tag" "region" {
  name = "${var.region}"
}

module "shared" {
  source                = "./shared"
  region                = "${var.region}"
  image                 = "${var.image}"
  size                  = "${var.size}"
  do_token              = "${var.do_token}"
  consul_version        = "${var.consul_version}"
  consul_servers        = "${var.consul_servers}"
  consul_service        = "${var.consul_service}"
  vault_version         = "${var.vault_version}"
  vault_servers         = "${var.vault_servers}"
  vault_service         = "${var.vault_service}"
  consul_encryption_key = "${var.consul_encryption_key}"
  ssl_pki_dir           = "${local.ssl_pki_dir}"
  ssl_bin_dir           = "${local.ssl_bin_dir}"
}
