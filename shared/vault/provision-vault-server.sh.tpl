#!/bin/bash

set -ex

# Wait for cloud-init to finish.
echo "Waiting 180 seconds for cloud-init to complete."
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo "Waiting ..."; sleep 2; done'

VAULT_VERSION=${vault_version}
NODE_NAME=`curl ${instance_hostname_url}`
INSTANCE_PRIVATE_IP=`curl ${instance_private_ip_url}`


#######################################
# VAULT SERVER INSTALL
#######################################

# Install Consul
echo "Downloading Vault version $${VAULT_VERSION} ..."
cd /tmp/
curl -q -s https://releases.hashicorp.com/vault/$${VAULT_VERSION}/vault_$${VAULT_VERSION}_linux_amd64.zip -o vault.zip

# Install Consul; and secure it
echo "Installing Vault ..."
unzip vault.zip
rm vault.zip
mv vault /usr/local/sbin/vault

chown root:${service} /usr/local/sbin/vault
chmod ug+x /usr/local/sbin/vault

echo "Vault installation complete ..."

# TODO
# Re-evaluate firewall rules for Vault external access
#
# # Secure HTTP port 8500 from external access
# # Need iptables-persistent to ensure rules are loaded at boot
#
# # But first, let's not save current rules as part of package configuration
# echo iptables-persistent    iptables-persistent/autosave_v4    boolean false | debconf-set-selections
#
# # Then, we can install iptables-persistent, making sure we disable any interactive bits at the end
# DEBIAN_FRONTEND=noninteractive apt-get install -qq -y iptables-persistent
#
# # Now let's setup the iptables rules
# # Allow only 'root' and 'vault' users to connect to TCP/8500 (Consul SSL)
# iptables -A OUTPUT -m tcp -p tcp --dport 8500 -m owner --uid-owner vault -j ACCEPT
# iptables -A OUTPUT -m tcp -p tcp --dport 8500 -m owner --uid-owner root -j ACCEPT
# iptables -A OUTPUT -p tcp -m tcp --dport 8500 -j REJECT
# # Just for good measure, reject anything going to Consul non-SSL port
# iptables -A OUTPUT -p tcp -m tcp --dport 8501 -j REJECT
#
# # And finally, let's save these to the file that iptables-persistent reads
# iptables-save > /etc/iptables/rules.v4


#######################################
# VAULT CONFIGURATION
#######################################
# TODO
# Remove advertise_addr, since it defaults to being bind_addr
# Remove leave_on_terminate=false, since server=true makes it redundant
#

tee /etc/vault/config.hcl > /dev/null <<EOF
cluster_name = "vault-${region}"

listener "tcp" {
  address        = "$$INSTANCE_PRIVATE_IP:8200"
  tls_cert_file  = "/etc/vault/ssl/vault-##server_idx+ca.crt"
  tls_key_file   = "/etc/vault/ssl/vault-##server_idx.key"
}

storage "consul" {
  path           = "vault/"
  address        = "127.0.0.1:8500"
  scheme         = "https"

  tls_ca_file    = "/etc/vault/ssl/ca.crt"
  tls_cert_file  = "/etc/vault/ssl/vault-##server_idx+ca.crt"
  tls_key_file   = "/etc/vault/ssl/vault-##server_idx.key"
}
EOF


tee /etc/systemd/system/vault-server.service > /dev/null <<EOF
[Unit]
Description=Vault Server
Requires=network-online.target
After=network-online.target

[Service]
EnvironmentFile=-/etc/sysconfig/vault
Restart=on-failure
User=${service}
Group=${service}
LimitMEMLOCK=infinity
ExecStart=/usr/local/sbin/vault server -config=/etc/vault/config.hcl
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
