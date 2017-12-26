#!/bin/bash

set -ex

# Wait for cloud-init to finish.
echo "Waiting 180 seconds for cloud-init to complete."
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo "Waiting ..."; sleep 2; done'

# Create user
useradd -d /srv/${service} -s /bin/false ${service}

# Setup configuration directory; and secure it
mkdir -pm 0750 /etc/${service}/ssl
chown -R root:${service} /etc/${service}

# Setup Consul home and data directories; and secure it
mkdir -pm 0750 /srv/${service}
mkdir -p /srv/${service}/data
chown -R ${service}: /srv/${service}
