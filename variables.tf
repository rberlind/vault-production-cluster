//-------------------------------------------------------------------
// Vault settings
//-------------------------------------------------------------------

variable "vault_download_url" {
    default = "https://s3-us-west-2.amazonaws.com/hc-enterprise-binaries/vault/ent/0.10.3/vault-enterprise_0.10.3%2Bent_linux_amd64.zip"
    description = "URL to download Vault"

}

variable "consul_download_url" {
    default = "https://s3-us-west-2.amazonaws.com/hc-enterprise-binaries/consul/ent/1.2.1/consul-enterprise_1.2.1%2Bent_linux_amd64.zip"
    description = "URL to download Consul"
}

variable "vault_config" {
  description = "Configuration (text) for Vault"
  default = <<EOF
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
  backend "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}
ui=true
EOF
}

variable "consul_server_config" {
    description = "Configuration (text) for Consul"
    default = <<EOF
{
  "log_level": "INFO",
  "server": true,
  "ui": true,
  "data_dir": "/opt/consul/data",
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "advertise_addr": "IP_ADDRESS",
  "bootstrap_expect": 5,
  "retry_join": ["provider=aws tag_key=ConsulAutoJoin tag_value=TAG_VALUE region=us-east-1"],
  "enable_syslog": true,
  "service": {
    "name": "consul"
  },
  "performance": {
    "raft_multiplier": 1
  }
}
EOF
}

variable "consul_client_config" {
    description = "Configuration (text) for Consul"
    default = <<EOF
{
  "log_level": "INFO",
  "server": false,
  "data_dir": "/opt/consul/data",
  "bind_addr": "IP_ADDRESS",
  "client_addr": "127.0.0.1",
  "retry_join": ["provider=aws tag_key=ConsulAutoJoin tag_value=TAG_VALUE region=us-east-1"],
  "enable_syslog": true,
  "service": {
    "name": "consul-client"
  },
  "performance": {
    "raft_multiplier": 1
  }
}
EOF
}

//-------------------------------------------------------------------
// AWS settings
//-------------------------------------------------------------------

variable "ami" {
    default = "ami-759bc50a"
    description = "AMI for Vault instances"
}

variable "public_ip" {
    default = false
    description = "should ec2 instance have public ip?"
}

variable "vault_name_prefix" {
    default = "vault"
    description = "prefix used in resource names"
}

variable "consul_name_prefix" {
    default = "consul"
    description = "prefix used in resource names"
}

variable "availability_zones" {
    default = "us-east-1a,us-east-1b,us-east-1c"
    description = "Availability zones for launching the Vault instances"
}

variable "vault_elb_health_check" {
    default = "HTTP:8200/v1/sys/health?standbyok=true"
    description = "Health check for Vault servers"
}

variable "consul_elb_health_check" {
    default = "HTTP:8500/v1/agent/self"
    description = "Health check for Consul servers"
}

variable "elb_internal" {
    default = true
    description = "make ELB internal or external"
}

variable "instance_type" {
    default = "t2.medium"
    description = "Instance type for Vault and Consul instances"
}

variable "key_name" {
    default = "default"
    description = "SSH key name for Vault and Consul instances"
}

variable "vault_nodes" {
    default = "3"
    description = "number of Vault instances"
}

variable "consul_nodes" {
    default = "5"
    description = "number of Consul instances"
}

variable "subnets" {
    description = "list of subnets to launch Vault within"
}

variable "vpc_id" {
    description = "VPC ID"
}

variable "owner" {
    description = "value of owner tag on EC2 instances"
}

variable "ttl" {
    description = "value of ttl tag on EC2 instances"
}

variable "auto_join_tag" {
    description = "value of ConsulAutoJoin tag used by Consul cluster"
}
