#!/bin/bash

src () {
  echo "Check and source: $1"
  [ -f "$1" ] && . "$1"
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

src "${DIR}/bin/functions"
src "${DIR}/bin/parameters"

# Cleanout current certs and db
rm -rf ${DIR}/CA/{certindex*,serial*}
rm -rf ${DIR}/pki/*

# Setup new db
touch ${DIR}/CA/certindex
echo "0A" > ${DIR}/CA/serial

openssl req -x509 -newkey rsa:4096 -days 3650 -nodes \
        -keyout ${DIR}/pki/ca.key                    \
        -out ${DIR}/pki/ca.crt                       \
        -subj "/C=${C}/O=${O}/OU=${OU}/CN=${CA_CN}"
