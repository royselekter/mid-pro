variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}


variable "region" {
  description = "AWS region for VMs"
  default = "us-east-1"
}


variable "clients" {
  description = "The number of consul client instances"
  default = 1
}

variable "consul_version" {
  description = "The version of Consul to install (server and client)."
  default     = "1.4.0"
}

variable "ami" {
  description = "ami to use"
  default = "ami-0565af6e282977273"
}


# keys
variable "keypair_name" {
  description = "name of ssh key to attach to hosts genereted during apply"
  default="opsschool_project_keypair"
}
variable "pem_key_name" {
  description = "name of ssh key to attach to hosts genereted during apply"
  default     = "opsschool_project_keypair.pem"
  # default     = "terraform-keypair.pem"
}


variable "network_address_space" {
  default = "192.168.0.0/16"
}

variable "pub1_address_space" {
  default = "192.168.10.0/24"
}


variable "private_address_space" {
  default = "192.168.15.0/24"
}

#security group

resource "aws_security_group" "terra_vpc_sg" {
  name = "Terraform_SG"
  description = "ssh for now"
  vpc_id = "${aws_vpc.terra_vpc.id}"


  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "SSH"
  }
ingress {
    from_port = 65433
    to_port = 65433
    protocol = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "consulb"
  }

  ingress {
    from_port = 30036
    to_port = 30036
    protocol = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "k8s app access"
  }

  ingress {
    from_port = 6443
    to_port = 6443
    protocol = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "k8s"
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "http"
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "https"
  }

  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "Allow consul UI access from the world"
  }

  ingress {
    from_port = 8300
    to_port = 8300
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "consul"
  }

  ingress {
    from_port = 179
    to_port = 179
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "calico"
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "4"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "calico"
  }


  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "ICMP"
  }


    ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all inside security group"
  }

  ingress {
   from_port   = 9090
   to_port     = 9090
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
   description = "prometheus"
 }

  ingress {
     from_port   = 9100
     to_port     = 9100
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
     description = "prometheus"
   }
  ingress {
       from_port   = 3000
       to_port     = 3000
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
       description = "grafana"
     }

egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
   description = "all"
 }


}

