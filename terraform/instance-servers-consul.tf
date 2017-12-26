resource "digitalocean_droplet" "server_consul" {
  image              = "${var.image}"
  name               = "${var.consul_service}-${count.index}"
  region             = "${var.region}"
  size               = "${var.size}"
  tags               = ["${digitalocean_tag.region.id}"]
  ssh_keys           = ["${digitalocean_ssh_key.main.id}"]
  private_networking = true

  count = "${var.consul_servers}"

  connection {
    user        = "root"
    private_key = "${file(var.private_key_path)}"
  }

  #
  # Consul
  #
  provisioner "remote-exec" {
    inline = [
      "${module.shared.install_tools}",
      "${module.shared.setup_dependencies_consul}",
      "${module.shared.install_dnsmasq}",
    ]
  }
}

# Base setup complete.
# For dynamic cert creation, we need to hand-off to a null_resource
# coupled wtih a local-exec.
# Then, we have to connect to the nodes to upload the newly generated certs.

resource "null_resource" "generate_consul_certs" {
  count = "${var.consul_servers}"

  connection {
    host        = "${element(digitalocean_droplet.server_consul.*.ipv4_address, count.index)}"
    user        = "root"
    private_key = "${file(var.private_key_path)}"
  }

  # Write hex format of server ID to local file as a temporary holding place
  provisioner "local-exec" {
    command     = "echo -n $(printf '0x%x' ${element(digitalocean_droplet.server_consul.*.id, count.index)}) > _idx_/server_idx_${element(digitalocean_droplet.server_consul.*.id, count.index)}.txt"
    interpreter = ["/bin/bash", "-c"]
  }

  # Consul agent keys
  provisioner "local-exec" {
    command = "${local.ssl_bin_dir}/02.createConsulKey.sh ${element(digitalocean_droplet.server_consul.*.ipv4_address_private, count.index)} ${file("_idx_/server_idx_${element(digitalocean_droplet.server_consul.*.id, count.index)}.txt")}"
  }

  # Consul certs
  provisioner "file" {
    source      = "${local.ssl_pki_dir}/ca.crt"
    destination = "/etc/consul/ssl/ca.crt"
  }

  provisioner "file" {
    source      = "${local.ssl_pki_dir}/consul-${file("_idx_/server_idx_${element(digitalocean_droplet.server_consul.*.id, count.index)}.txt")}.crt"
    destination = "/etc/consul/ssl/consul-${file("_idx_/server_idx_${element(digitalocean_droplet.server_consul.*.id, count.index)}.txt")}.crt"
  }

  provisioner "file" {
    source      = "${local.ssl_pki_dir}/consul-${file("_idx_/server_idx_${element(digitalocean_droplet.server_consul.*.id, count.index)}.txt")}.key"
    destination = "/etc/consul/ssl/consul-${file("_idx_/server_idx_${element(digitalocean_droplet.server_consul.*.id, count.index)}.txt")}.key"
  }

  # Setup the Consul environment variables
  provisioner "file" {
    content = "${replace("${module.shared.setup_consul_environment}",
                        "##server_idx", "${file("_idx_/server_idx_${element(digitalocean_droplet.server_consul.*.id, count.index)}.txt")}"
                        )
                }"

    destination = "/etc/profile.d/setup-consul-environment.sh"
  }

  # Install Consul server
  provisioner "remote-exec" {
    inline = [
      "${replace("${module.shared.install_consul_server}",
                 "##server_idx", "${file("_idx_/server_idx_${element(digitalocean_droplet.server_consul.*.id, count.index)}.txt")}"
                )
        }",
    ]
  }

  provisioner "remote-exec" {
    inline = ["${module.shared.start_service_consul}"]
  }

  provisioner "local-exec" {
    command = "rm -rf _idx_/server_idx_${element(digitalocean_droplet.server_consul.*.id, count.index)}.txt"
  }
}
