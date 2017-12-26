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
   1. BASH (kind of standard, isn't it? :smiley: )
   4. Terraform (https://terraform.io/)
   5. OpenSSL (to help create certs)
   6. jq (not mandatory, but helps connecting to newly deployed nodes)


## Getting Started
In order to get this project to a state where it can automatically deploy the nodes on the cloud, a simple bootstrapping proess is needed.
### 1. Clone repo
First, let's clone the repo to a location on our computer.
`git clone https://github.com/HanSooloo/terraform-consul-vault.git`

### 2. Bootstrap
`cd terraform-consul-vault/terraform`
`./bootstrap.sh`

The bootstrap script will request 3 pieces of information to help generate the `.env` file.
1.  **Digital Ocean API key:**  this should be a read/write API key that you have already setup.  For details on how to set it up, see the excellent guide here: https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2
2.  **Private key path:**  (assuming an SSH keypair was created beforehand) the location of the private key that will be used to connect to the cloud instances.  Defaults to `$HOME/.ssh/digitalocean.com`
3.  **Public key path:**  (assuming an SSH keypair was created beforehand) the location of the public key that will be provisioned to the cloud instances.  Defaults to `$HOME/.ssh/digitalocean.com.pub`
4.  **Consul encryption key:** though this is not a user input, it is automatically generated based on a 16-byte random number for use in encrypting Consul traffic.

This will product output like the following:

```
$ ./bootstrap.sh
Developer Bootstrap

This script bootstraps a fresh repo to the point where it can start provisioning nodes in the cloud.

The steps are as follows:

[1] Create the .env file that will be sourced by the various scripts.

[2] Configure the API token used to communicate with the provider.

[3] Configure the SSH public and private key paths.

[4] Create requisite directories for server ID handling.


Enter the DigitalOcean API token: YOUR-DIGITAL-OCEAN-API-KEY-HERE
Enter the SSH private key path ($HOME/.ssh/digitalocean.com.key):
Enter the SSH public key path ($HOME/.ssh/digitalocean.com):

.env file:
--------------------------------------------------------------------------------
export TF_VAR_do_token="YOUR-DIGITAL-OCEAN-API-KEY-HERE"
export TF_VAR_private_key_path="$HOME/.ssh/digitalocean.com"
export TF_VAR_public_key_path="$HOME/.ssh/digitalocean.com.pub"
export TF_VAR_consul_encryption_key="MGTjNe3HHEcCoVIMYrF28A=="
--------------------------------------------------------------------------------
```

### 3. Initialize Terraform
Before we deploy anything to the cloud we need to make sure the Terraform directory is properly initialized.

`terraform init`

### 4. Apply!
In the last step, we ask Terraform to do its magic.  However, instead of calling the `terraform` binary directly, we are using a little helper script that sources the environment variables in `.env`.

`./apply.sh`

If you would like to use `terraform` by itself, make sure to run `. ./env` in the `terraform-consul-vault/terraform` directory beforehand.  This will export the key `TF_VAR_` environment variables so that `terraform` does not ask you for input.

##### Credits
This repo is inspired by the great examples at HashiCorp's `atlas-examples` repo at https://github.com/hashicorp/atlas-examples.
