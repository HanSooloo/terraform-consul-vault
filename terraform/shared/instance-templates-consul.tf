data "template_file" "setup_dependencies_consul" {
  template = "${file("${path.module}/common/setup-dependencies.sh.tpl")}"

  vars {
    service = "${var.consul_service}"
  }
}

output "setup_dependencies_consul" {
  value = "${data.template_file.setup_dependencies_consul.rendered}"
}

#
# CONSUL SERVER
#
data "template_file" "install_consul_server" {
  template = "${file("${path.module}/consul/provision-consul-server.sh.tpl")}"

  vars {
    region                  = "${var.region}"
    consul_version          = "${var.consul_version}"
    consul_servers          = "${var.consul_servers}"
    service                 = "${var.consul_service}"
    instance_hostname_url   = "${var.do_instance_hostname_url}"
    instance_private_ip_url = "${var.do_instance_private_ip_url}"
    do_token                = "${var.do_token}"
    consul_encryption_key   = "${var.consul_encryption_key}"
  }
}

output "install_consul_server" {
  value = "${data.template_file.install_consul_server.rendered}"
}

data "template_file" "setup_consul_environment" {
  template = "${file("${path.module}/consul/setup-consul-environment.sh.tpl")}"
}

output "setup_consul_environment" {
  value = "${data.template_file.setup_consul_environment.rendered}"
}

data "template_file" "start_service_consul" {
  template = "${file("${path.module}/common/start-service.sh.tpl")}"

  vars {
    service = "${var.consul_service}-server"
  }
}

output "start_service_consul" {
  value = "${data.template_file.start_service_consul.rendered}"
}

#
# CONSUL AGENT
#

data "template_file" "install_consul_agent" {
  template = "${file("${path.module}/consul/provision-consul-agent.sh.tpl")}"

  vars {
    region                  = "${var.region}"
    consul_version          = "${var.consul_version}"
    service                 = "${var.consul_service}"
    instance_hostname_url   = "${var.do_instance_hostname_url}"
    instance_private_ip_url = "${var.do_instance_private_ip_url}"
    do_token                = "${var.do_token}"
    consul_encryption_key   = "${var.consul_encryption_key}"
  }
}

output "install_consul_agent" {
  value = "${data.template_file.install_consul_agent.rendered}"
}

data "template_file" "start_service_consul_agent" {
  template = "${file("${path.module}/common/start-service.sh.tpl")}"

  vars {
    service = "${var.consul_service}-agent"
  }
}

output "start_service_consul_agent" {
  value = "${data.template_file.start_service_consul_agent.rendered}"
}
