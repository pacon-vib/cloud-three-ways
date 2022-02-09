terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "tf-example"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = local.aws_availability_zone

  tags = {
    Name = "tf-example"
  }
}

resource "aws_route_table" "public" {
  vpc_id =  aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.public.id
}

/*
resource "aws_network_interface" "foo" {
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}
*/

resource "aws_key_pair" "some_key" {
  key_name   = "some-key"
  public_key = var.ssh_key
}

resource "aws_security_group" "example" {
  name        = "we_allow_friendly_ssh"
  description = "Yeah cool allow friendly SSH this group ok"
  vpc_id      = aws_vpc.my_vpc.id
}

resource "aws_security_group_rule" "allow_friendly_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [local.friendly_cidr_block]
  #cidr_blocks = ["0.0.0.0/0"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = aws_security_group.example.id
}

resource "aws_instance" "foo" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  associate_public_ip_address = true
  subnet_id = aws_subnet.my_subnet.id
  depends_on = [aws_internet_gateway.gw] # For connectivity
  vpc_security_group_ids = [aws_security_group.example.id]
  key_name = aws_key_pair.some_key.key_name

  /*network_interface {
    network_interface_id = aws_network_interface.foo.id
    device_index         = 0
  }*/

  credit_specification {
    cpu_credits = "unlimited"
  }

  tags = {
    Name = var.vm_public_hostname
  }
}

output "vm_public_fqdn" {
  value = aws_instance.foo.public_dns
}

output "vm_public_ip_address" {
  value = aws_instance.foo.public_ip
}
