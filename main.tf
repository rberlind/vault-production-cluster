resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "${var.vault_name_prefix}"
  role        = "${aws_iam_role.instance_role.name}"
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = "${var.vault_name_prefix}"
  assume_role_policy = "${data.aws_iam_policy_document.instance_role.json}"
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "auto_discover_cluster" {
  name   = "${var.vault_name_prefix}-auto-discover-cluster"
  role   = "${aws_iam_role.instance_role.id}"
  policy = "${data.aws_iam_policy_document.auto_discover_cluster.json}"
}

data "aws_iam_policy_document" "auto_discover_cluster" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2messages:GetMessages",
      "ssm:UpdateInstanceInformation",
      "ssm:ListInstanceAssociations",
      "ssm:ListAssociations",
    ]

    resources = ["*"]
  }
}

// Security group for Vault
resource "aws_security_group" "vault" {
    name = "${var.vault_name_prefix}-sg"
    description = "Vault servers"
    vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "vault_ssh" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault_external_egress" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "egress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault_internal_egress" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "egress"
    from_port = 8200
    to_port = 8600
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.vault.id}"
}

resource "aws_security_group_rule" "vault_elb_access" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8200
    to_port = 8200
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.vault_elb.id}"
}

resource "aws_security_group_rule" "consul_elb_access" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.vault_elb.id}"
}

resource "aws_security_group_rule" "vault_cluster" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8201
    to_port = 8201
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.vault.id}"
}

// This rule allows Consul RPC.
resource "aws_security_group_rule" "consul_rpc" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8300
    to_port = 8300
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.vault.id}"
}

// This rule allows Consul Serf TCP.
resource "aws_security_group_rule" "vault_consul_serf_tcp" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8301
    to_port = 8302
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.vault.id}"
}

// This rule allows Consul Serf UDP.
resource "aws_security_group_rule" "vault_consul_serf_udp" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8301
    to_port = 8302
    protocol = "udp"
    source_security_group_id = "${aws_security_group.vault.id}"
}

// This rule allows Consul DNS.
resource "aws_security_group_rule" "consul_dns_tcp" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8600
    to_port = 8600
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.vault.id}"
}

// This rule allows Consul DNS.
resource "aws_security_group_rule" "consul_dns_udp" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8600
    to_port = 8600
    protocol = "udp"
    source_security_group_id = "${aws_security_group.vault.id}"
}

resource "aws_security_group" "vault_elb" {
    name = "${var.vault_name_prefix}-elb"
    description = "Vault ELB"
    vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "vault_elb_http" {
    security_group_id = "${aws_security_group.vault_elb.id}"
    type = "ingress"
    from_port = 8200
    to_port = 8200
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "consul_elb_http" {
    security_group_id = "${aws_security_group.vault_elb.id}"
    type = "ingress"
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault_elb_egress_to_vault" {
    security_group_id = "${aws_security_group.vault_elb.id}"
    type = "egress"
    from_port = 8200
    to_port = 8200
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.vault.id}"
}

resource "aws_security_group_rule" "vault_elb_egress_to_consul" {
    security_group_id = "${aws_security_group.vault_elb.id}"
    type = "egress"
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.vault.id}"
}
