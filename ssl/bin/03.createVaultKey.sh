#!/bin/bash
# set -ex
# $1: IP SAN to add to certificate
# $2: Server index number

src () {
  echo "Check and source: $1"
  [ -f "$1" ] && . "$1"
}

# Root of 'ssl' directory structure
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

src "${DIR}/bin/functions"
src "${DIR}/bin/parameters"

TFVARS="${DIR}/../terraform/terraform.tfvars"
DC=$( get_key "region" $TFVARS)
SRV_IDX=$2

export BOOTSTRAP_SSL_DIR="$DIR"

# Create cert sign request
echo "Creating CSR for vault-$SRV_IDX.$DC.local"
openssl req -newkey rsa:2048 -nodes -extensions v3_req               \
        -out    ${DIR}/pki/vault-$SRV_IDX.csr                        \
        -keyout ${DIR}/pki/vault-$SRV_IDX.key                        \
        -subj "/C=${C}/O=${O}/OU=${OU}/CN=vault-$SRV_IDX.$DC.local"

# Sign the request
echo "Signing CSR: vault-$SRV_IDX.$DC.local"
openssl ca -batch -config - -notext -extensions v3_req  \
        -in  ${DIR}/pki/vault-$SRV_IDX.csr              \
        -out ${DIR}/pki/vault-$SRV_IDX.crt <<EOF
[ ca ]
default_ca = bootstrap_ca

[ bootstrap_ca ]
dir = \$ENV::BOOTSTRAP_SSL_DIR
unique_subject = no
new_certs_dir = \$dir/pki
certificate = \$dir/pki/ca.crt
database = \$dir/CA/certindex
private_key = \$dir/pki/ca.key
serial = \$dir/CA/serial
default_days = 3650
default_md = sha256
policy = bootstrap_ca_policy
x509_extensions = bootstrap_ca_extensions

[ bootstrap_ca_policy ]
countryName = supplied
organizationName = supplied
organizationalUnitName = supplied
commonName = supplied

[ bootstrap_ca_extensions ]
basicConstraints = CA:false
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth,clientAuth

[ req ]
req_extensions = v3_req

[ v3_req ]
subjectAltName = @alt_names

[ alt_names ]
IP.0 = 127.0.0.1
IP.1 = $1
EOF

cat ${DIR}/pki/vault-$SRV_IDX.crt ${DIR}/pki/ca.crt > ${DIR}/pki/vault-$SRV_IDX+ca.crt

echo "Issued certificate:"
openssl x509 -in ${DIR}/pki/vault-$SRV_IDX.crt -subject -issuer -noout
