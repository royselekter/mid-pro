provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
  version = "~> 1.0"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "terra_vpc" {
  cidr_block = "${var.network_address_space}"
  instance_tenancy     = "default"

}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.terra_vpc.id}"
}

resource "aws_eip" "terra_eip" {
  vpc      = true
  depends_on = ["aws_internet_gateway.igw"]
}

resource "aws_route_table" "terra_rt" {
    vpc_id = "${aws_vpc.terra_vpc.id}"
    tags {
        Name = "public_rt_terraform"
    }

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }

}

resource "aws_route_table" "terra_rt_private" {
    vpc_id = "${aws_vpc.terra_vpc.id}"
    tags {
        Name = "private_rt_terraform"
    }

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_nat_gateway.nat.id}"
    }

}

//NAT gateway & assosiate the private route table

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.terra_eip.id}"
  subnet_id     = "${aws_subnet.pub1.id}"
  depends_on = ["aws_internet_gateway.igw"]

}


# Create the Internet Access

resource "aws_route" "Terraform_VPC_internet_access" {
       route_table_id        = "${aws_route_table.terra_rt.id}"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id             = "${aws_internet_gateway.igw.id}"
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "Terraform_pub1" {
       subnet_id      = "${aws_subnet.pub1.id}"
       route_table_id = "${aws_route_table.terra_rt.id}"
}

resource "aws_route_table_association" "Terraform_private" {
  subnet_id = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.terra_rt_private.id}"
}

resource "aws_subnet" "pub1" {
  cidr_block = "${var.pub1_address_space}"
  vpc_id = "${aws_vpc.terra_vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_subnet" "private" {
  cidr_block = "${var.private_address_space}"
  vpc_id = "${aws_vpc.terra_vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

}


# create key pair
resource "tls_private_key" "opsschool_project_rsa_key" {
 algorithm = "RSA"
 rsa_bits  = 4096
}

resource "aws_key_pair" "opsschool_project_key" {
 key_name   = "opsschool_project_keypair"
 public_key = "${tls_private_key.opsschool_project_rsa_key.public_key_openssh}"
}

resource "null_resource" "chmod_400_key" {
 provisioner "local-exec" {
   command = "chmod 400 ${path.module}/${local_file.private_key.filename}"
 }
}

resource "local_file" "private_key" {
 sensitive_content = "${tls_private_key.opsschool_project_rsa_key.private_key_pem}"
 filename          = "${var.pem_key_name}"
}

data "template_file" "jenkins_init"{
 template = "${file("jenki_config.sh")}"
 vars = {
   key_base64 = "${base64encode(tls_private_key.opsschool_project_rsa_key.private_key_pem)}"
 }
}


data "template_file" "ansi_init"{
 template = "${file("ansi_config.sh")}"
 vars = {
   key_base64 = "${base64encode(tls_private_key.opsschool_project_rsa_key.private_key_pem)}"
 }
}



#machines

resource "aws_instance" "bastian" {
  ami = "ami-0ac019f4fcb7cb7e6"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.pub1.id}"
  private_ip = "192.168.10.10"
  associate_public_ip_address = true
  key_name = "${var.keypair_name}"
  security_groups = ["${aws_security_group.terra_vpc_sg.id}"]
  depends_on=["aws_instance.ansible","aws_instance.k8s"]
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
  user_data = "${file("./bastian.sh")}"


  connection {
   user = "ubuntu"  # todo use var
   type = "ssh"
   private_key = "${file("${path.module}/${local_file.private_key.filename}")}"
 }

 provisioner "file" {
   source = "./${local_file.private_key.filename}"
   destination = ".ssh/${local_file.private_key.filename}"
 }

 provisioner "remote-exec" {
   inline = [
     "chmod 700 .ssh/${local_file.private_key.filename}",
     "cat .ssh/${local_file.private_key.filename} >> .ssh/id_rsa",
     "chmod 700 .ssh/id_rsa",
     "scp -o stricthostkeychecking=no /home/ubuntu/.ssh/id_rsa ubuntu@192.168.10.40:/home/ubuntu/.ssh/id_rsa",
     "ssh -o stricthostkeychecking=no ubuntu@192.168.10.40 'git clone https://github.com/royselekter/k8s_repo.git'",

     "ssh -o stricthostkeychecking=no ubuntu@192.168.15.20  \"while [ ! -f /tmp/userdata-init-done ]; do sleep 2; echo wait for ansible. retrying ...; done; echo ansible is ready\"",
     "ssh -o stricthostkeychecking=no ubuntu@192.168.15.20 ./ansible_repo/run_pb.sh",

     "ssh -o stricthostkeychecking=no ubuntu@192.168.15.30  \"while [ ! -f /tmp/userdata-init-done ]; do sleep 2; echo wait for jenkins. retrying ...; done; echo jenkins is ready\"",
     "ssh -o stricthostkeychecking=no ubuntu@192.168.15.30 sudo java -jar ~ubuntu/jenkins-cli.jar -s http://localhost:8080/ -auth jenkins:R@y217153 build test_me_app"

   ]
 }
  tags {
    Name = "basti"
  }
}


resource "aws_instance" "k8s" {
  ami = "ami-024a64a6685d05041"
  instance_type   = "t2.medium"
  subnet_id       = "${aws_subnet.pub1.id}"
  private_ip      = "192.168.10.40"
  associate_public_ip_address = true 
  key_name      = "${var.keypair_name}"
  security_groups = ["${aws_security_group.terra_vpc_sg.id}"]
  #user_data = "${file("./mini.sh")}"

  tags {
    Name = "k8s"
  }
}


resource "aws_instance" "mini_1" {
  ami             = "ami-0ac019f4fcb7cb7e6"
  instance_type   = "t2.micro"
  subnet_id       = "${aws_subnet.pub1.id}"
  private_ip      = "192.168.10.51"
  associate_public_ip_address = true
  source_dest_check = false
  key_name        = "${var.keypair_name}"
  security_groups = ["${aws_security_group.terra_vpc_sg.id}"]
  user_data = "${file("./mini1.sh")}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"

  tags {
    Name = "mini_1"
  }
}


resource "aws_instance" "mini_2" {
  ami             = "ami-0ac019f4fcb7cb7e6"
  instance_type   = "t2.micro"
  subnet_id       = "${aws_subnet.pub1.id}"
  private_ip      = "192.168.10.52"
  associate_public_ip_address = true
  source_dest_check = false
  key_name        = "${var.keypair_name}"
  security_groups = ["${aws_security_group.terra_vpc_sg.id}"]
  user_data = "${file("./mini2.sh")}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"

  tags {
    Name = "mini_2"
  }
}

resource "aws_instance" "ansible" {
  ami             = "ami-0ac019f4fcb7cb7e6"
  instance_type   = "t2.micro"
  subnet_id       = "${aws_subnet.private.id}"
  private_ip      = "192.168.15.20"
  key_name        = "${var.keypair_name}"
  security_groups = ["${aws_security_group.terra_vpc_sg.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
  depends_on=["aws_instance.k8s","aws_instance.mini_1","aws_instance.mini_2"]

  user_data = "${data.template_file.ansi_init.rendered}"

  connection {
   user = "ubuntu"  # todo use var
   type = "ssh"
   private_key = "${file("${path.module}/${local_file.private_key.filename}")}"
 }

  tags {
    Name = "ansible"
  }
}


resource "aws_instance" "jenkins" {
  ami = "ami-0af606abb291c3661"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private.id}"
  private_ip = "192.168.15.30"
  key_name = "${var.keypair_name}"
  security_groups = ["${aws_security_group.terra_vpc_sg.id}"]
  user_data = "${data.template_file.jenkins_init.rendered}"
  depends_on = ["aws_instance.k8s","aws_instance.mini_1","aws_instance.mini_2","local_file.private_key"]

  tags {
    Name = "jenki"
  }
}



















//
//bastion - 192.168.10.10
//ansible - 192.168.15.20
//jenkins - 192.168.15.30
//k8s_Master - 192.168.10.40
//minion_1 - 192.168.10.51
//minion_2 - 192.168.10.52


