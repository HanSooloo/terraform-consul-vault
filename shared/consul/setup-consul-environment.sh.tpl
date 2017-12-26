#!/bin/sh

export CONSUL_CACERT="/etc/consul/ssl/ca.crt"
export CONSUL_CLIENT_CERT="/etc/consul/ssl/consul-##server_idx.crt"
export CONSUL_CLIENT_KEY="/etc/consul/ssl/consul-##server_idx.key"
export CONSUL_HTTP_SSL=true
