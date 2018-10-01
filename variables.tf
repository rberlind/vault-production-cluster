//-------------------------------------------------------------------
// AWS settings
//-------------------------------------------------------------------

variable "vault_name_prefix" {
    default = "vault"
    description = "prefix used in resource names"
}

variable "consul_name_prefix" {
    default = "consul"
    description = "prefix used in resource names"
}

variable "vpc_id" {
    description = "VPC ID"
}
