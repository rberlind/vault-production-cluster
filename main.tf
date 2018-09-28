data "template_file" "install_vault" {
    template = "${file("${path.module}/scripts/install_vault_server.sh.tpl")}"

    vars {
        install_unzip       = "${var.unzip_command}"
        vault_download_url  = "${var.vault_download_url}"
        consul_download_url  = "${var.consul_download_url}"
        vault_config        = "${var.vault_config}"
        consul_config        = "${var.consul_client_config}"
        tag_value            = "${var.auto_join_tag}"
    }
}

data "template_file" "install_consul" {
    template = "${file("${path.module}/scripts/install_consul_server.sh.tpl")}"

    vars {
        install_unzip       = "${var.unzip_command}"
        consul_download_url  = "${var.consul_download_url}"
        consul_config        = "${var.consul_server_config}"
        tag_value            = "${var.auto_join_tag}"
    }
}

// We launch Vault into an ASG so that it can properly bring them up for us.
resource "aws_autoscaling_group" "vault" {
    name = "${aws_launch_configuration.vault.name}"
    launch_configuration = "${aws_launch_configuration.vault.name}"
    availability_zones = ["${split(",", var.availability_zones)}"]
    min_size = "${var.vault_nodes}"
    max_size = "${var.vault_nodes}"
    desired_capacity = "${var.vault_nodes}"
    health_check_grace_period = 15
    health_check_type = "EC2"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    load_balancers = ["${aws_elb.vault.id}"]

    tags = [
      {
        key = "Name"
        value = "${var.vault_name_prefix}"
        propagate_at_launch = true
      },
      {
        key = "ConsulAutoJoin"
        value = "${var.auto_join_tag}"
        propagate_at_launch = true
      },
      {
        key = "owner"
        value = "${var.owner}"
        propagate_at_launch = true
      },
      {
        key = "ttl"
        value = "${var.ttl}"
        propagate_at_launch = true
      }
    ]

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_launch_configuration" "vault" {
    name_prefix = "${var.vault_name_prefix}"
    image_id = "${var.ami}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.vault.id}"]
    user_data = "${data.template_file.install_vault.rendered}"
    associate_public_ip_address = "${var.public_ip}"
    iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
    root_block_device {
      volume_type = "io1"
      volume_size = 50
      iops = "2500"
    }

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "consul" {
    name = "${aws_launch_configuration.consul.name}"
    launch_configuration = "${aws_launch_configuration.consul.name}"
    availability_zones = ["${split(",", var.availability_zones)}"]
    min_size = "${var.consul_nodes}"
    max_size = "${var.consul_nodes}"
    desired_capacity = "${var.consul_nodes}"
    health_check_grace_period = 15
    health_check_type = "EC2"
    vpc_zone_identifier = ["${split(",", var.subnets)}"]
    load_balancers = ["${aws_elb.consul.id}"]

    tags = [
      {
        key = "Name"
        value = "${var.consul_name_prefix}"
        propagate_at_launch = true
      },
      {
        key = "ConsulAutoJoin"
        value = "${var.auto_join_tag}"
        propagate_at_launch = true
      },
      {
        key = "owner"
        value = "${var.owner}"
        propagate_at_launch = true
      },
      {
        key = "ttl"
        value = "${var.ttl}"
        propagate_at_launch = true
      }
    ]

    lifecycle {
      create_before_destroy = true
    }

    depends_on = ["aws_autoscaling_group.vault"]
}

resource "aws_launch_configuration" "consul" {
    name_prefix = "${var.consul_name_prefix}"
    image_id = "${var.ami}"
    instance_type = "${var.instance_type}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.consul.id}"]
    user_data = "${data.template_file.install_consul.rendered}"
    associate_public_ip_address = "${var.public_ip}"
    iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
    root_block_device {
      volume_type = "io1"
      volume_size = 100
      iops = "5000"
    }

    lifecycle {
      create_before_destroy = true
    }
}


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

// Security group for Consul
resource "aws_security_group" "consul" {
    name = "${var.consul_name_prefix}-sg"
    description = "Consul servers"
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

resource "aws_security_group_rule" "consul_ssh" {
    security_group_id = "${aws_security_group.consul.id}"
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

// This rule allows Vault HTTP API access to individual nodes, since each will
// need to be addressed individually for unsealing.
resource "aws_security_group_rule" "vault_http_api" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8200
    to_port = 8200
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault_cluster" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8201
    to_port = 8201
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

// This rule allows Consul HTTP API access to individual nodes.
resource "aws_security_group_rule" "consul_http_api" {
    security_group_id = "${aws_security_group.consul.id}"
    type = "ingress"
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

// This rule allows Consul RPC.
resource "aws_security_group_rule" "consul_rpc" {
    security_group_id = "${aws_security_group.consul.id}"
    type = "ingress"
    from_port = 8300
    to_port = 8300
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

// This rule allows Consul Serf TCP.
resource "aws_security_group_rule" "vault_consul_serf_tcp" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8301
    to_port = 8301
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

// This rule allows Consul Serf TCP.
resource "aws_security_group_rule" "consul_serf_tcp" {
    security_group_id = "${aws_security_group.consul.id}"
    type = "ingress"
    from_port = 8301
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

// This rule allows Consul Serf UDP.
resource "aws_security_group_rule" "vault_consul_serf_udp" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "ingress"
    from_port = 8301
    to_port = 8301
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
}

// This rule allows Consul Serf UDP.
resource "aws_security_group_rule" "consul_serf_udp" {
    security_group_id = "${aws_security_group.consul.id}"
    type = "ingress"
    from_port = 8301
    to_port = 8302
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
}

// This rule allows Consul DNS.
resource "aws_security_group_rule" "consul_dns_tcp" {
    security_group_id = "${aws_security_group.consul.id}"
    type = "ingress"
    from_port = 8600
    to_port = 8600
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

// This rule allows Consul DNS.
resource "aws_security_group_rule" "consul_dns_udp" {
    security_group_id = "${aws_security_group.consul.id}"
    type = "ingress"
    from_port = 8600
    to_port = 8600
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault_egress" {
    security_group_id = "${aws_security_group.vault.id}"
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "consul_egress" {
    security_group_id = "${aws_security_group.consul.id}"
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

// Launch the ELB that is serving Vault. This has proper health checks
// to only serve healthy, unsealed Vaults.
resource "aws_elb" "vault" {
    name = "${var.vault_name_prefix}-elb"
    connection_draining = true
    connection_draining_timeout = 400
    internal = "${var.elb_internal}"
    subnets = ["${split(",", var.subnets)}"]
    security_groups = ["${aws_security_group.vault_elb.id}"]

    listener {
        instance_port = 8200
        instance_protocol = "tcp"
        lb_port = 8200
        lb_protocol = "tcp"
    }

    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 3
        timeout = 5
        target = "${var.vault_elb_health_check}"
        interval = 15
    }
}

// Launch the ELB that is serving Consul. This has proper health checks
// to only serve healthy, unsealed Consuls.
resource "aws_elb" "consul" {
    name = "${var.consul_name_prefix}-elb"
    connection_draining = true
    connection_draining_timeout = 400
    internal = "${var.elb_internal}"
    subnets = ["${split(",", var.subnets)}"]
    security_groups = ["${aws_security_group.consul_elb.id}"]

    listener {
        instance_port = 8500
        instance_protocol = "tcp"
        lb_port = 8500
        lb_protocol = "tcp"
    }

    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 3
        timeout = 5
        target = "${var.consul_elb_health_check}"
        interval = 15
    }
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

resource "aws_security_group" "consul_elb" {
    name = "${var.consul_name_prefix}-elb"
    description = "Consul ELB"
    vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "consul_elb_http" {
    security_group_id = "${aws_security_group.consul_elb.id}"
    type = "ingress"
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault_elb_egress" {
    security_group_id = "${aws_security_group.vault_elb.id}"
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "consul_elb_egress" {
    security_group_id = "${aws_security_group.consul_elb.id}"
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
