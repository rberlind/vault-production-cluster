key_name = "roger-vault"
vault_name_prefix = "benchmark-vault"
consul_name_prefix = "benchmark-consul"
vpc_id = "vpc-07b9e9b345ad12921"
subnets = "subnet-07e11a155b1d15faa,subnet-0f1aa1afac01c5ed6,subnet-0f24064f5cf8514a3"

elb_internal = false
public_ip = true

# This downloads Vault Enterprise by default
vault_download_url = "https://releases.hashicorp.com/vault/0.10.4/vault_0.10.4_linux_amd64.zip"

# This downloads Consul Enterprise by default
consul_download_url = "https://releases.hashicorp.com/consul/1.2.2/consul_1.2.2_linux_amd64.zip"

instance_type = "m5.2xlarge"

owner = "roger@hashicorp.com"
ttl = "-1"
auto_join_tag = "benchmark-demo-cluster"
