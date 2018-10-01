// Vault Security Group ID
output "vault_security_group" {
  value = "${aws_security_group.vault.id}"
}

// ELB Security Group ID
output "vault_elb_security_group" {
  value = "${aws_security_group.vault_elb.id}"
}

// IAM Instance Profile Name
output "iam_profile_name" {
  value = "${aws_iam_instance_profile.instance_profile.name}"
}
