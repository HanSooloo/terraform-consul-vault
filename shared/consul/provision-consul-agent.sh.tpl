#!/bin/bash

set -ex

# Wait for cloud-init to finish.
echo "Waiting 180 seconds for cloud-init to complete."
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo "Waiting ..."; sleep 2; done'

CONSUL_VERSION=${consul_version}
NODE_NAME=`curl ${instance_hostname_url}`
INSTANCE_PRIVATE_IP=`curl ${instance_private_ip_url}`


#######################################
# CONSUL CLIENT INSTALL
#######################################

# Install Consul
echo "Downloading Consul version $${CONSUL_VERSION} ..."
cd /tmp/
curl -q -s https://releases.hashicorp.com/consul/$${CONSUL_VERSION}/consul_$${CONSUL_VERSION}_linux_amd64.zip -o consul.zip

# Install Consul; and secure it
echo "Installing Consul ..."
unzip consul.zip
rm consul.zip
mv consul /usr/local/sbin/consul

chown root:${service} /usr/local/sbin/consul
chmod ug+x /usr/local/sbin/consul

echo "Consul installation complete ..."


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
tee /etc/consul/config.json > /dev/null <<EOF
{
  "node_name": "$$NODE_NAME",

  "data_dir": "/srv/consul/data",

  "client_addr": "127.0.0.1",
  "bind_addr": "$$INSTANCE_PRIVATE_IP",
  "advertise_addr": "$$INSTANCE_PRIVATE_IP",

  "encrypt": "${consul_encryption_key}",
  "ports": {
    "https": 8500,
    "http":  8501
  },
  "ca_file": "/etc/consul/ssl/ca.crt",
  "cert_file": "/etc/consul/ssl/consul-##server_idx.crt",
  "key_file": "/etc/consul/ssl/consul-##server_idx.key",
  "verify_incoming": true,
  "verify_outgoing": true,

  "leave_on_terminate": false,
  "skip_leave_on_interrupt": true,

  "retry_join": ["provider=digitalocean region=${region} tag_name=${region} api_token=${do_token}"],

  "datacenter": "${region}",
  "server": false

}
EOF

tee /etc/systemd/system/consul-agent.service > /dev/null <<EOF
[Unit]
Description=Consul Client
Requires=network-online.target
After=network-online.target

[Service]
EnvironmentFile=-/etc/sysconfig/vault
Restart=on-failure
User=${service}
Group=${service}
ExecStart=/usr/local/sbin/consul agent -config-dir=/etc/consul/config.json
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
