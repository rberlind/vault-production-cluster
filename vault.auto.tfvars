#For Ubuntu, set unzip_command to "sudo apt-get install -y curl unzip"
#For RHEL, set unzip_command to "sudo yum -y install unzip"
unzip_command = "sudo yum -y install unzip"

# EC2 Instance Profile Name
instance_profile_name = "benchmark-vault20181001135800895900000002"

# Vault Security Group ID
vault_sg_id = "sg-0de4f38fb2d0a0643"

# ELB Security Group ID
elb_sg_id = "sg-0634aae1fd7f0e9fc"

# Ubuntu would be ami-759bc50a or ami-059eeca93cf09eebd
ami = "ami-6871a115" # RHEL 7.5
instance_type = "m5.large"

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
vault_download_url = "https://s3-us-west-2.amazonaws.com/hc-enterprise-binaries/vault/ent/1.1.2/vault-enterprise_1.1.2%2Bent_linux_amd64.zip"

# This downloads Consul Enterprise by default
consul_download_url = "https://s3-us-west-2.amazonaws.com/hc-enterprise-binaries/consul/ent/1.5.0/consul-enterprise_1.5.0%2Bent_linux_amd64.zip"

# Used to auto-join Consul servers into cluster
auto_join_tag = "benchmark-demo-cluster"

# These are only needed for HashiCorp SEs
owner = "roger@hashicorp.com"
ttl = "-1"
