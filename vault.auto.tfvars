unzip_command = "sudo yum -y install unzip"
key_name = "roger-vault"
vault_name_prefix = "benchmark-vault"
consul_name_prefix = "benchmark-consul"
vpc_id = "vpc-096fc2379b384b480"
subnets = "subnet-004b0106fca7dea1c"

elb_internal = false
public_ip = true

vault_nodes = "3"
consul_nodes = "3"

# This downloads Vault Enterprise by default
vault_download_url = "https://releases.hashicorp.com/vault/0.11.1/vault_0.11.1_linux_amd64.zip"

# This downloads Consul Enterprise by default
  consul_download_url = "https://releases.hashicorp.com/consul/1.2.3/consul_1.2.3_linux_amd64.zip"

# Ubuntu would be ami-759bc50a or ami-059eeca93cf09eebd
ami = "ami-6871a115" # RHEL 7.5
instance_type = "m5.2xlarge"

owner = "roger@hashicorp.com"
ttl = "-1"
auto_join_tag = "benchmark-demo-cluster"
