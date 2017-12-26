#!/bin/bash

set -ex

# Wait for cloud-init to finish.
echo "Waiting 180 seconds for cloud-init to complete."
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo "Waiting ..."; sleep 2; done'

#######################################
# DNSMASQ INSTALL
#######################################
echo "Installing Dnsmasq ..."

apt-get -qq -y update
apt-get -qq -y install dnsmasq-base dnsmasq

echo "Configuring Dnsmasq ..."

# grep DO's own name servers so that we can give it to dnsmasq for FWD'ing
DNS1=$(grep dns-nameservers /etc/network/interfaces.d/50-cloud-init.cfg | head -n1 | sed -e 's/^[ \t]*//' | cut -f2 -d ' ')
DNS2=$(grep dns-nameservers /etc/network/interfaces.d/50-cloud-init.cfg | head -n1 | sed -e 's/^[ \t]*//' | cut -f3 -d ' ')

# Configure dnsmasq to process Consul; and FWD everything else
echo "server=/consul/127.0.0.1#8600" >> /etc/dnsmasq.d/consul
echo "listen-address=127.0.0.1" >> /etc/dnsmasq.d/consul
echo "server=$DNS1" >> /etc/dnsmasq.d/consul
echo "server=$DNS2" >> /etc/dnsmasq.d/consul
echo "bind-interfaces" >> /etc/dnsmasq.d/consul

echo "Restarting dnsmasq service ..."
systemctl restart dnsmasq.service

echo "dnsmasq installation complete ..."


#######################################
# resolv.conf WITH dnsmasq @127.0.0.1
#######################################

# Modify the DO cloud-init so that we survive a rebuild of server
echo "Modify the DO cloud-init network interface file ..."
sed -i '/dns-nameservers/c\    dns-nameservers 127.0.0.1' /etc/network/interfaces.d/50-cloud-init.cfg

# Backup/deactivate the lo.inet file so that it doesn't get auto-inserted into resolv.conf
mv /run/resolvconf/interface/lo.inet /run/resolvconf/interface/backup.lo.inet

# Let's rebuild /etc/resolv.conf so that 127.0.0.1 is the sole provider; since dnsmasq is going to FWD non-Consul stuff to DO nameservers
# echo "Restarting resolvconf service ..."
# systemctl restart resolvconf.service
echo "Running resolvconf to rebuild /etc/resolv.conf ..."
resolvconf -u
