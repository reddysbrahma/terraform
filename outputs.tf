
output "instance_id1" {
  value = "${aws_instance.web1.*.id}"
}

output "instance_id2" {
  value = "${aws_instance.web2.*.id}"
}

output "elb-dns" {
  value = "${aws_elb.elb1.dns_name}"
}
