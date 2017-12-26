data "template_file" "setup_dependencies_vault" {
  template = "${file("${path.module}/common/setup-dependencies.sh.tpl")}"

  vars {
    service = "${var.vault_service}"
  }
}

output "setup_dependencies_vault" {
  value = "${data.template_file.setup_dependencies_vault.rendered}"
}

data "template_file" "install_vault_server" {
  template = "${file("${path.module}/vault/provision-vault-server.sh.tpl")}"

  vars {
    region                  = "${var.region}"
    vault_version           = "${var.vault_version}"
    vault_servers           = "${var.vault_servers}"
    service                 = "${var.vault_service}"
    instance_hostname_url   = "${var.do_instance_hostname_url}"
    instance_private_ip_url = "${var.do_instance_private_ip_url}"
    do_token                = "${var.do_token}"
    consul_encryption_key   = "${var.consul_encryption_key}"
  }
}

output "install_vault_server" {
  value = "${data.template_file.install_vault_server.rendered}"
}

data "template_file" "setup_vault_environment" {
  template = "${file("${path.module}/vault/setup-vault-environment.sh.tpl")}"
}

output "setup_vault_environment" {
  value = "${data.template_file.setup_vault_environment.rendered}"
}

data "template_file" "start_service_vault" {
  template = "${file("${path.module}/common/start-service.sh.tpl")}"

  vars {
    service = "${var.vault_service}-server"
  }
}

output "start_service_vault" {
  value = "${data.template_file.start_service_vault.rendered}"
}
