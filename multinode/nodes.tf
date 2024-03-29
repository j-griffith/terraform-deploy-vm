# instance the provider

variable "hostname_format"{
  type = string
  default = "deb-%02d"
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "kube" {
  name = "kube"
  type = "dir"
  path = "/tmp/kube"
}

resource "libvirt_volume" "stretch_base_image" {
  name = "stretch_base_image"
  pool = "kube"
  source = "http://10.117.253.42:8080/debian-9-openstack-amd64.qcow2"
}

resource "libvirt_volume" "volume" {
  pool = "kube"
  name = "${format(var.hostname_format, count.index + 1)}.qcow2"
  base_volume_id = libvirt_volume.stretch_base_image.id
  count = 3
}

resource "libvirt_volume" "os_volume" {
  name = "os-${format(var.hostname_format, count.index + 1)}.qcow2"
  base_volume_id = "${libvirt_volume.stretch_base_image.id}"
  pool = "kube"
  size = 10737418240
  count = 3
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = "kube"
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

resource "libvirt_domain" "domain" {
  name = "kube-${count.index}"
  memory = "4096"
  vcpu = 4
  count = 3

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
    volume_id = element(libvirt_volume.os_volume.*.id, count.index)
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = "true"
  }

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

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  #provisioner "remote-exec" {
  #  inline = [
  #    "hostnamectl set-hostname ${format(var.hostname_format, count.index)}"
  #  ]
    #connection {
    #  type = "ssh"
    #  user = "debian"
    #  host = self.host
    #}
    #}
}

output "ips" {
  value = libvirt_domain.domain.*.network_interface.0.addresses
}

terraform {
  required_version = ">= 0.12"
}
