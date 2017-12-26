resource "digitalocean_droplet" "server_vault" {
  image              = "${var.image}"
  name               = "${var.vault_service}-${count.index}"
  region             = "${var.region}"
  size               = "${var.size}"
  tags               = ["${digitalocean_tag.region.id}"]
  ssh_keys           = ["${digitalocean_ssh_key.main.id}"]
  private_networking = true

  count = "${var.vault_servers}"

  connection {
    user        = "root"
    private_key = "${file(var.private_key_path)}"
  }

  #
  # Vault
  #
  provisioner "remote-exec" {
    inline = [
      "${module.shared.install_tools}",
      "${module.shared.setup_dependencies_vault}",
      "${module.shared.setup_dependencies_consul}",
      "${module.shared.install_dnsmasq}",
    ]
  }
}

# Doing this really weird stuff because:
# 1. Wanted to reference the newly created droplet ID inside a format() statement, but it turns out that _INSIDE_ fomrat() we get a different object ID, not the one from the droplet.
# 2. So, instead, we have to store the IDs in an file where it is Hex encoded.
# THIS IS WAAAY TOO MESSED UP !!!

# Base setup complete.
# For dynamic cert creation, we need to hand-off to a null_resource
# coupled wtih a local-exec.
# Then, we have to connect to the nodes to upload the newly generated certs.

resource "null_resource" "generate_vault_certs" {
  count = "${var.vault_servers}"

  connection {
    host        = "${element(digitalocean_droplet.server_vault.*.ipv4_address, count.index)}"
    user        = "root"
    private_key = "${file(var.private_key_path)}"
  }

  # Write hex format of server ID to local file as a temporary holding place
  provisioner "local-exec" {
    command = " echo -n $(printf '0x%x' ${element(digitalocean_droplet.server_vault.*.id, count.index)}) > _idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt"

    # FOR DEBUG
    # echo count.index: ${count.index} --- do.ids: ${data.null_data_source.values.inputs.do_droplet_ids} --- do.id: ${format("0x%x", element(split(",", data.null_data_source.values.inputs.do_droplet_ids), count.index) )} --- do.id: ${element(split(",", data.null_data_source.values.inputs.do_droplet_ids), count.index)} "

    # REAL CODE
    # echo -n $(printf '0x%x' ${element(digitalocean_droplet.server_vault.*.id, count.index)}) > _idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt"
    interpreter = ["/bin/bash", "-c"]
  }

  # Consul agent keys
  provisioner "local-exec" {
    command = "${local.ssl_bin_dir}/02.createConsulKey.sh ${element(digitalocean_droplet.server_vault.*.ipv4_address_private, count.index)} ${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}"
  }

  # Vault server keys
  provisioner "local-exec" {
    command = "${local.ssl_bin_dir}/03.createVaultKey.sh ${element(digitalocean_droplet.server_vault.*.ipv4_address_private, count.index)} ${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}"
  }

  # Consul certs
  provisioner "file" {
    source      = "${local.ssl_pki_dir}/ca.crt"
    destination = "/etc/consul/ssl/ca.crt"
  }

  provisioner "file" {
    source      = "${local.ssl_pki_dir}/consul-${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}.crt"
    destination = "/etc/consul/ssl/consul-${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}.crt"
  }

  provisioner "file" {
    source      = "${local.ssl_pki_dir}/consul-${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}.key"
    destination = "/etc/consul/ssl/consul-${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}.key"
  }

  # Vault certs
  provisioner "file" {
    source      = "${local.ssl_pki_dir}/ca.crt"
    destination = "/etc/vault/ssl/ca.crt"
  }

  provisioner "file" {
    source      = "${local.ssl_pki_dir}/vault-${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}+ca.crt"
    destination = "/etc/vault/ssl/vault-${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}+ca.crt"
  }

  provisioner "file" {
    source      = "${local.ssl_pki_dir}/vault-${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}.key"
    destination = "/etc/vault/ssl/vault-${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}.key"
  }

  # Setup the Consul environment variables
  provisioner "file" {
    content = "${replace("${module.shared.setup_consul_environment}",
                         "##server_idx", "${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}") }"

    destination = "/etc/profile.d/setup-consul-environment.sh"
  }

  # Setup the Vault environment variables
  provisioner "file" {
    content = "${replace("${module.shared.setup_vault_environment}",
                         "##server_idx", "${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}"
                        )
                }"

    destination = "/etc/profile.d/setup-vault-environment.sh"
  }

  # Install Vault server + Consul agent
  provisioner "remote-exec" {
    inline = [
      "${replace("${module.shared.install_vault_server}",
                 "##server_idx", "${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}"
                )
        }",
      "${replace("${module.shared.install_consul_agent}",
                 "##server_idx", "${file("_idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt")}"
                )
        }",
    ]
  }

  provisioner "remote-exec" {
    inline = ["${module.shared.start_service_consul_agent}"]
  }

  provisioner "remote-exec" {
    inline = ["${module.shared.start_service_vault}"]
  }

  provisioner "local-exec" {
    command = "rm -rf _idx_/server_idx_${element(digitalocean_droplet.server_vault.*.id, count.index)}.txt"
  }
}
