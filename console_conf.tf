//# Create the user-data for the Consul server
////data "template_file" "bastian" {
////  count    = "${var.}"
////  template = "${file("${path.module}/templates/consul.sh.tpl")}"
//
//  vars {
//    consul_version = "${var.consul_version}"
//    config = <<EOF
//     "node_name":  "opsschool-server-${count.index+1}",
//     "server": true,
//     "bootstrap_expect": 2,
//     "ui": true,
//     "client_addr": "0.0.0.0"
//    EOF
//  }
//}
//
//# Create the user-data for the Consul agent
//data "template_file" "ansible" {
//  count    = "${var.clients}"
//  template = "${file("${path.module}/templates/consul.sh.tpl")}"
//
//  vars {
//    consul_version = "${var.consul_version}"
//    config = <<EOF
//     "node_name": "ansible",
//     "enable_script_checks": true,
//     "server": false
//    EOF
//  }
//}
////
////# Create the Consul cluster
////resource "aws_instance" "consul_server" {
////  count = "${var.servers}"
////
////  ami           = "${lookup(var.ami, var.region)}"
////  instance_type = "t2.micro"
////  key_name      = "${var.keypair_name}"
////  subnet_id = "subnet-0d58c3f9af9ae2805"
////
////  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
////  vpc_security_group_ids = ["${aws_security_group.opsschool_consul.id}"]
////
////  tags = {
////    Name = "opsschool-server-${count.index+1}"
////    consul_server = "true"
////  }
////
////  user_data = "${element(data.template_file.consul_server.*.rendered, count.index)}"
////}
////
////resource "aws_instance" "consul_client" {
////  count = "${var.clients}"
////
////  ami           = "${lookup(var.ami, var.region)}"
////  instance_type = "t2.micro"
////  key_name      = "${var.keypair_name}"
////  subnet_id = "subnet-0d58c3f9af9ae2805"
////
////  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
////  vpc_security_group_ids = ["${aws_security_group.opsschool_consul.id}"]
////
////  tags = {
////    Name = "opsschool-client-${count.index+1}"
////  }
////
////  user_data = "${element(data.template_file.consul_client.*.rendered, count.index)}"
////}
//
//
