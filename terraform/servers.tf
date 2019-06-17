provider "aws" {
  region = "us-east-1"
  profile = "default"
}

resource "aws_key_pair" "yubikey" {
  key_name = "yubikey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDG/RD5sbTzUkjGQNmUAZLNAh2mQNHcs781KU7vBJI3VOPlhGrqkcfd35cjZkFNMpDOBM4FnXNyJwtKrtZ7SARrInVuOMiMjdS4g3J+MiZ5LMJG12XkBYbbsw5hc18Sa4FYVYadJtNNIOIVhZfvu8/CbxGnybca6ucdlO/dVOwmXEVytraxSjCif4lf2O8TxVqAZpvzzA9WCS7pEZbDftIzeEoXpk0stucrWOrjTuRRPAK0SY12Fnd/5kmEPUCOW+oNaIGeD+6beoyg/5TIm2Rnr/yP1BLrf8xjd1JZe06zQIl4pPZncH7Wgx4uATsQtDhup9DNAEY0eSttsXzqFbZsvY2MuO7pD7e17N/NkdH3Y6vis0UsiWNks5zZ4dcqurvnph+JBb9vKqER6VKa+0FnCaR++McVuLToeYe+XstWTAoVj9+ZqaelmwY/sxM4KpynGXyIW3uHQUdqA2KH35eZEu9uKZLmVRUMyJ0b27FOyExXuc0GveZbSIgSuQTy9/+9V63sUJaohMbXFOSL4cg4zFomZ+TOv3+qTeZNG70/Oo2SJ3xQ9gloKFI0BxCFvapa9PrgYpbVPM0l/1kjDx/GV92hoqDtMbmcc1VTy/IlXkb48dY51tyrn1mCi9kWDf3ovcifXdQwoTtbuCVWnBDLGFSetWb/beC25aP6v5YUAQ== jstrunk:0x66495EF8"
}

resource "aws_instance" "gluster-servers" {
  # https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9
  count = 3
  # ami = "ami-9887c6e7" # CentOS 7 1805_01
  ami = "ami-0240b09539b9692a0" # RHEL-7.6_HVM_GA-20190128-x86_64-0-Access2-GP2 (east-1)
  ebs_optimized = "true"
  instance_type = "m5.xlarge"
  key_name = "yubikey"
  root_block_device {
    delete_on_termination = "true"
    volume_type = "gp2"
  }
  security_groups = ["gluster-servers"]
  tags = {
    Name = "gluster-${count.index}"
    gluster-group = "us-east-2-c00-g00"
    # gluster-master is the first one
    gluster-master = "${count.index == 0 ? "us-east-2-c00" : "none"}"
  }
  ebs_block_device {
    delete_on_termination = "true"
    #device_name = "/dev/nvme1n1"
    device_name = "/dev/xvdb"
    encrypted = "true"
    volume_size = 100
    volume_type = "gp2"
  }
  ebs_block_device {
    delete_on_termination = "true"
    #device_name = "/dev/nvme1n2"
    device_name = "/dev/xvdc"
    encrypted = "true"
    volume_size = 100
    volume_type = "gp2"
  }
}

# Allocate an elastic ip for each gluster server
# This ensures a stable external IP across shutdowns, but incurrs $0.005 per
# hour that the machines are turned off.
resource "aws_eip" "gluster-server-addresses" {
  count = 3
  instance = "${element(aws_instance.gluster-servers.*.id, count.index)}"
  vpc = "true"
}

resource "aws_security_group" "gluster-servers" {
  name        = "gluster-servers"
  description = "Group for gluster servers"

  ingress {
    description = "allow all internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = "true"
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "glusterd"
    from_port   = 24007
    to_port     = 24007
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "gluster bricks"
    from_port   = 49152
    to_port     = 49251
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
