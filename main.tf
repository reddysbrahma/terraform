provider "aws" {
region = var.region
}

terraform {
  backend "s3" {
    region = "us-east-1"
    encrypt = true
    bucket = "brahma-terraform-test"
    dynamodb_table = "tflocktable"
    key = "test.tfstate"
    lock_table = "false"
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}




resource "aws_security_group" "websg" {
  name = "security_group_for_web_server"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = "${var.cidr}"
  }


}

resource "aws_security_group_rule" "ssh" {
  security_group_id = "${aws_security_group.websg.id}"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = "${var.cidr}"
}

resource "aws_security_group" "elbsg" {
  name = "security_group_for_elb"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = "${var.cidr}"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = "${var.cidr}"
  }
}


resource aws_instance "web1" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${lookup(var.instance_type,var.env )}"
vpc_security_group_ids = ["${aws_security_group.websg.id}"]
  key_name = "elb"

user_data = <<-EOF
#!/bin/bash
echo “hello, I am web1” >index.html
nohup busybox httpd -f -p 80 &
EOF
}

resource aws_instance "web2" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${lookup(var.instance_type,var.env )}"
  vpc_security_group_ids = ["${aws_security_group.websg.id}"]
  key_name = "elb"

  user_data = <<-EOF
#!/bin/bash
echo “hello, I am web2” >index.html
nohup busybox httpd -f -p 80 &
EOF
}

#data aws_availability_zones "availablezones" {}

resource "aws_elb" "elb1" {
  name = "terraform-elb"
  #availability_zones = "${data.aws_availability_zones.availablezones[count.index]}"
  availability_zones = "${var.azs}"
  security_groups = ["${aws_security_group.elbsg.id}"]
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }
  instances = ["${aws_instance.web1.id}","${aws_instance.web2.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

}

