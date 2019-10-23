# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "stretch" {
  name = "stretch"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-stretch"
}

# We fetch the latest stretch release image from their mirrors
resource "libvirt_volume" "stretch-qcow2" {
  name   = "stretch-qcow2"
  pool   = libvirt_pool.stretch.name
  source = "https://cdimage.debian.org/cdimage/openstack/current-9/debian-9-openstack-amd64.qcow2"
  format = "qcow2"
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.stretch.name
}

# Create the machine
resource "libvirt_domain" "domain-stretch" {
  name   = "stretch-terraform"
  memory = "4096"
  vcpu   = 4

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name = "default"
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.stretch-qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

terraform {
  required_version = ">= 0.12"
}

# IPs: use wait_for_lease true or after creation use terraform refresh and terraform show for the ips of domain
