terraform {
  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
  }
}

provider "esxi" {
  esxi_hostname = "192.168.1.100"
  esxi_hostport = "22"
  esxi_hostssl = "443"
  esxi_username = "root"
  esxi_password = "Welkom01!"  # Pas dit aan naar jouw wachtwoord
}

variable "vm_count" {
  default = 2
}

variable "vm_names" {
  default = ["webserver6", "database3"]
}

resource "esxi_guest" "vms" {
  count       = var.vm_count
  guest_name  = var.vm_names[count.index]
  disk_store  = "Datastore01"
  memsize     = "2048"
  numvcpus    = "2"
  ovf_source  = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"

  guestinfo = {
    "metadata"          = filebase64("metadata.yaml")
    "metadata.encoding" = "base64"
    "userdata"          = filebase64("userdata.yaml")
    "userdata.encoding" = "base64"
  }

  network_interfaces {
    virtual_network = "VM Network"
  }
}

# **Genereer automatisch een Ansible Inventory bestand**
resource "local_file" "inventory" {
  filename = "inventory.ini"
  content = <<EOT
[webservers]
webserver ansible_host=${esxi_guest.vms[0].ip_address} ansible_user=webuser ansible_ssh_private_key_file=~/.ssh/skylab

[database]
database ansible_host=${esxi_guest.vms[1].ip_address} ansible_user=webuser ansible_ssh_private_key_file=~/.ssh/skylab
EOT
}
