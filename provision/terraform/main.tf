provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_instance" "master" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "${var.ec2_instance_type}"
    key_name = "${var.ec2_keypair}"

    vpc_security_group_ids = ["${aws_security_group.master.id}", "${aws_security_group.nodes.id}"]
    subnet_id = "${element(var.vpc_subnets, 0)}"

    associate_public_ip_address = "${var.associate_public_ip_address}"

    root_block_device {
        volume_type = "${var.volume_type}"
        volume_size = "${var.volume_size}"
    }

    tags = "${merge(var.tags, map("Name", format("%s-master", var.name_prefix)))}"
    volume_tags = "${merge(var.tags, map("Name", format("%s-master", var.name_prefix)))}"
}

resource "aws_instance" "validators" {
    count = "${var.num_validator_nodes}"

    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "${var.ec2_instance_type}"
    key_name = "${var.ec2_keypair}"

    vpc_security_group_ids = ["${aws_security_group.nodes.id}"]
    subnet_id = "${element(var.vpc_subnets, count.index + 1)}"

    associate_public_ip_address = "${var.associate_public_ip_address}"

    root_block_device {
        volume_type = "${var.volume_type}"
        volume_size = "${var.volume_size}"
    }

    tags = "${merge(var.tags, map("Name", format("%s-validator-%d", var.name_prefix, count.index)))}"
    volume_tags = "${merge(var.tags, map("Name", format("%s-validator-%d", var.name_prefix, count.index)))}"
}

resource "aws_instance" "observers" {
    count = "${var.num_validator_nodes}"

    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "${var.ec2_instance_type}"
    key_name = "${var.ec2_keypair}"

    vpc_security_group_ids = ["${aws_security_group.nodes.id}"]
    subnet_id = "${element(var.vpc_subnets, count.index)}"

    associate_public_ip_address = "${var.associate_public_ip_address}"

    root_block_device {
        volume_type = "${var.volume_type}"
        volume_size = "${var.volume_size}"
    }

    tags = "${merge(var.tags, map("Name", format("%s-observer-%d", var.name_prefix, count.index)))}"
    volume_tags = "${merge(var.tags, map("Name", format("%s-observer-%d", var.name_prefix, count.index)))}"
}

#######################################################
# Security Group
#######################################################

resource "aws_security_group" "master" {
    name = "${var.name_prefix}-master"
    description = "Parity PoA Network Master"
    vpc_id = "${var.vpc_id}"

    tags = "${merge(var.tags, map("Name", format("%s-master", var.name_prefix)))}"
}

resource "aws_security_group" "nodes" {
    name = "${var.name_prefix}"
    description = "Parity PoA Network Nodes Rules"
    vpc_id = "${var.vpc_id}"

    tags = "${merge(var.tags, map("Name", format("%s", var.name_prefix)))}"
}

resource "aws_security_group_rule" "ssh_in" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${concat(list(data.aws_vpc.this.cidr_block), var.incoming_ssh_cidr)}"]

    security_group_id = "${aws_security_group.nodes.id}"
}

resource "aws_security_group_rule" "ethereum_tcp" {
    count = "${length(var.ethereum_tcp_ports)}"

    type = "ingress"
    from_port = "${element(var.ethereum_tcp_ports, count.index)}"
    to_port = "${element(var.ethereum_tcp_ports, count.index)}"
    protocol = "tcp"
    cidr_blocks = ["${concat(list(data.aws_vpc.this.cidr_block), var.incoming_ssh_cidr)}"]

    security_group_id = "${aws_security_group.nodes.id}"
}

resource "aws_security_group_rule" "ethereum_udp" {
    count = "${length(var.ethereum_udp_ports)}"

    type = "ingress"
    from_port = "${element(var.ethereum_udp_ports, count.index)}"
    to_port = "${element(var.ethereum_udp_ports, count.index)}"
    protocol = "udp"
    cidr_blocks = ["${concat(list(data.aws_vpc.this.cidr_block), var.incoming_ssh_cidr)}"]

    security_group_id = "${aws_security_group.nodes.id}"
}