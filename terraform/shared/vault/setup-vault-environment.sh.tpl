#!/bin/sh

export VAULT_CACERT="/etc/vault/ssl/ca.crt"
export VAULT_CLIENT_CERT="/etc/vault/ssl/vault-##server_idx+ca.crt"
export VAULT_CLIENT_KEY="/etc/vault/ssl/vault-##server_idx.key"
export VAULT_ADDR="https://`curl http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address 2>/dev/null`:8200"
