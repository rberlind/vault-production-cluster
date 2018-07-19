key_name = "roger-vault"
vault_name_prefix = "benchmark-vault"
consul_name_prefix = "benchmark-consul"
vpc_id = "vpc-07b9e9b345ad12921"
subnets = "subnet-07e11a155b1d15faa,subnet-0f1aa1afac01c5ed6,subnet-0f24064f5cf8514a3"

elb_internal = false
public_ip = true

# This downloads Vault Enterprise by default
vault_download_url = "https://s3-us-west-2.amazonaws.com/hc-enterprise-binaries/vault/ent/0.10.3/vault-enterprise_0.10.3%2Bent_linux_amd64.zip"

# This downloads Consul Enterprise by default
consul_download_url = "https://s3-us-west-2.amazonaws.com/hc-enterprise-binaries/consul/ent/1.2.1/consul-enterprise_1.2.1%2Bent_linux_amd64.zip"

instance_type = "m5.xlarge"

owner = "roger@hashicorp.com"
ttl = "-1"
auto_join_tag = "benchmark-demo-cluster"
