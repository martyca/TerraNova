provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "eu-central-1"
}

module "ssh" {
  source = "./keypair"
}

variable "access_key" {}
variable "secret_key" {}
locals {
  ovpnfile = "${pathexpand("~/CLIENT.ovpn")}"
}

resource "aws_security_group" "terranova" {
  name        = "terranova"
  description = "Allow tcp 22 and 1194"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "terranova" {
  ami             = "ami-c86c3f23"
  instance_type   = "t2.micro"
  key_name        = "terranova"
  security_groups = ["terranova"]

  connection {
    user        = "ec2-user"
    private_key = "${file("~/.ssh/terranova.pem")}"
  }

  provisioner "file" {
    source      = "scripts/openvpn-install.sh"
    destination = "/tmp/openvpn-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y",
      "sudo yum -y update",
      "sudo yum -y install openvpn iptables openssl ca-certificates",
      "sudo bash /tmp/openvpn-install.sh",
      "sudo cp /root/CLIENT.ovpn /tmp/CLIENT.ovpn",
    ]
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/terranova.pem ec2-user@${self.public_ip}:/tmp/CLIENT.ovpn ${local.ovpnfile}"
  }
}

output "address" {
  value = "${aws_instance.terranova.*.public_dns}"
}

output "ip" {
  value = "${aws_instance.terranova.*.public_ip}"
}

output "ovpnfile" {
  value = "${local.ovpnfile}"
}
