#!/bin/bash

echo "Developer Bootstrap"
echo
echo "This script bootstraps a fresh repo to the point where it can start provisioning nodes in the cloud."
echo
echo "The steps are as follows:"
echo
echo "[1] Create the .env file that will be sourced by the various scripts."
echo
echo "[2] Configure the API token used to communicate with the provider."
echo
echo "[3] Configure the SSH public and private key paths."
echo
echo "[4] Create requisite directories for server ID handling."
echo
echo

read -r -p 'Enter the DigitalOcean API token: ' DO_TOKEN

read -r -p 'Enter the SSH private key path ($HOME/.ssh/digitalocean.com.key): ' DO_PRV_KEY

read -r -p 'Enter the SSH public key path ($HOME/.ssh/digitalocean.com): ' DO_PUB_KEY

tee ./.env > /dev/null <<EOF
export TF_VAR_do_token="$DO_TOKEN"
export TF_VAR_private_key_path="${DO_PRV_KEY:-\$HOME/.ssh/digitalocean.com}"
export TF_VAR_public_key_path="${DO_PUB_KEY:-\$HOME/.ssh/digitalocean.com.pub}"
export TF_VAR_consul_encryption_key="$(dd if=/dev/urandom bs=1 count=16 2>/dev/null | base64)"
EOF

echo
echo ".env file:"
printf '%.s-' {1..80}; echo
cat .env
printf '%.s-' {1..80}; echo
