# terraform-consul-vault
A fully automated Terraform project that sets up 3-node Consul and Vault clusters with full TLS end to end security across nodes.
Basic configuration is provided in the `terraform.tfvars` file to help customize the project according to your needs.
Here is a quick summary of what the deployed service delivers:
1. 3-node Consul cluster
   1. TLS-enabled operation on both CLI and API access.
   2. TLS verify mode for HTTP API and RPC (incoming and outgoing).
   2. Allows HTTPS UI (no client cert from browser required).
   3. Random Serf encryption key bootstrapped into the cluster (configurable).
   2. Automatic bootstrap (no need to manually setup an initial bootstrap server and manually join other servers).
1. 3-node Vault cluster
    1. TLS-enabled operation on both CLI and API access.
    3. TLS-enabled communication with local Consul agent.
4. Self-signed CA to help bootstrap the service.
    1. Setup to create per-node keys/certs to facilitate full TLS operation.
    2. Per-node Consul agent, server and Vault server certificates.

What this does not do (yet):
- [ ] Proper ACLs to control access
- [ ] Automatically unseal Vault instances
- [ ] Load balancing / advertising services as load balancer addresses
- [ ] Probably lots of other things :-)

Pre-requisites:
1. Digital Ocean account to create the service nodes
2. (preferably) macOS or Linux machine with:
   3. BASH (kind of standard, isn't it? :-) )
   4. Terraform (https://terraform.io/)
   5. OpenSSL (to help create certs)
   6. jq (not mandatory, but helps connecting to newly deployed nodes)
