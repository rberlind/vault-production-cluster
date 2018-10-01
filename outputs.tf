output "vault_address" {
    value = "${aws_elb.vault.dns_name}"
}

output "consul_address" {
    value = "${aws_elb.consul.dns_name}"
}
