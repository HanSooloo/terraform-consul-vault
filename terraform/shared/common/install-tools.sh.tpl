#!/bin/bash

set -ex

# Wait for cloud-init to finish.
echo "Waiting 180 seconds for cloud-init to complete."
timeout 180 /bin/bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo "Waiting ..."; sleep 2; done'

  # Install common tools
  echo "Installing common tools ..."
  apt-get -qq -y update
  apt-get install -qq -y unzip htop
