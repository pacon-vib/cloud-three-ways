# Cloud Three Ways
#
# This file invokes a set of modules, each of which deploys a virtual machine to a particular cloud. 

variable "ssh_public_key_file" {
  type = string
  description = "Path to a file containing a public key which will be used to authenticate users logging in to the VMs. This can be generated with `ssh-keygen -t rsa -f path/to/file`. Use the `.pub` file here, and then log in using the corresponding private key using `ssh -i path/to/file user@publichostname`."
}

variable "vm_username" {
  type = string
  description = "User name for logging in to the VMs. (Note: on AWS I don't know how to set this, so you have to use the `ubuntu` user based on the OS disk image.)"
  default = "foomin"
}

variable "regions" {
  type = any # object, but cbf writing out the schema lol
  description = "Map of cloud provider names to region/location names. Where (geographically) would you like your VMs to live?"
  default = {
    azure = "Australia East"
    aws = "ap-southeast-2"
    gcp = "australia-southeast1"
  }
}

variable "vm_public_hostname_base" {
  type = string
  description = "Base string for VM public hostnames (used for DNS entries)"
  default = "someserver"
}

variable "friendly_ip_address" {
  type = string
  description = "Used to allow SSH connections to VMs only from this IP address. Currently only implemented for AWS. If this variable is an empty string, then Terraform will use Leafcloud's ifconfig.co service to get its own public IP address. So don't read this variable directly, use `local.friendly_ip_address`."
  default = ""
}

locals {
  vm_public_hostnames = {
    # Suffix the base hostname with the name of the relevant cloud
    for cloud_name in ["azure", "aws", "gcp"] : cloud_name => "${var.vm_public_hostname_base}${cloud_name}"
  }
  ssh_key = file(var.ssh_public_key_file)
  friendly_ip_address = var.friendly_ip_address != "" ? var.friendly_ip_address : local.own_public_ip
  own_public_ip = jsondecode(data.http.my_public_ip.body).ip
}

data "http" "my_public_ip" {
  url = "https://ifconfig.co/json"
  request_headers = {
    Accept = "application/json"
  }
}

module "azure" {
  source = "./azure"
  azure_location = var.regions.azure
  azure_resource_group_name = "threeways"
  vm_public_hostname = local.vm_public_hostnames.azure
  vm_username = var.vm_username
  ssh_key = local.ssh_key
}

module "aws" {
  source = "./aws"
  aws_region = var.regions.aws
  vm_public_hostname = local.vm_public_hostnames.aws
  friendly_ip_address = local.friendly_ip_address
  vm_username = var.vm_username
  ssh_key = local.ssh_key
}

module "gcp" {
  source = "./gcp"
  gcp_region = var.regions.gcp
  vm_public_hostname = local.vm_public_hostnames.gcp
  vm_username = var.vm_username
  ssh_key = local.ssh_key
}

output "yall_vms" {
  value = {
    azure = {
      "hostname" = module.azure.vm_public_fqdn
      "ip" = module.azure.vm_public_ip_address
    }
    aws = {
      "hostname" = module.aws.vm_public_fqdn
      "ip" = module.aws.vm_public_ip_address
    }
    gcp = {
      "hostname" = module.gcp.vm_public_fqdn
      "ip" = module.gcp.vm_public_ip_address
    }
  }
}
