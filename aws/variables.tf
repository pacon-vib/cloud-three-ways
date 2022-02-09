variable "aws_region" {}
variable "friendly_ip_address" {}
variable "vm_public_hostname" {}
variable "vm_username" {} # Not used
variable "ssh_key" {}

locals {
  aws_availability_zone = "${var.aws_region}a"
  friendly_cidr_block = "${var.friendly_ip_address}/32"
}
