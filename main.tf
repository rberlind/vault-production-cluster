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
        consul_nodes         = "${var.consul_nodes}"
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
    security_groups = ["${var.vault_sg_id}"]
    user_data = "${data.template_file.install_vault.rendered}"
    associate_public_ip_address = "${var.public_ip}"
    iam_instance_profile = "${var.instance_profile_name}"
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
    security_groups = ["${var.vault_sg_id}"]
    user_data = "${data.template_file.install_consul.rendered}"
    associate_public_ip_address = "${var.public_ip}"
    iam_instance_profile = "${var.instance_profile_name}"
    root_block_device {
      volume_type = "io1"
      volume_size = 100
      iops = "5000"
    }

    lifecycle {
      create_before_destroy = true
    }
}

// Launch the ELB that is serving Vault. This has proper health checks
// to only serve healthy, unsealed Vaults.
resource "aws_elb" "vault" {
    name = "${var.vault_name_prefix}-elb"
    connection_draining = true
    connection_draining_timeout = 400
    internal = "${var.elb_internal}"
    subnets = ["${split(",", var.subnets)}"]
    security_groups = ["${var.elb_sg_id}"]

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
    security_groups = ["${var.elb_sg_id}"]

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
