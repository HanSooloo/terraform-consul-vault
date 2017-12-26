data "template_file" "install_tools" {
  template = "${file("${path.module}/common/install-tools.sh.tpl")}"
}

output "install_tools" {
  value = "${data.template_file.install_tools.rendered}"
}

data "template_file" "install_dnsmasq" {
  template = "${file("${path.module}/common/install-dnsmasq.sh.tpl")}"
}

output "install_dnsmasq" {
  value = "${data.template_file.install_dnsmasq.rendered}"
}
