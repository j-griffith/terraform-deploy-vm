# instance the provider

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
  name = "volume-${count.index}"
  base_volume_id = libvirt_volume.stretch_base_image.id
  count = 3
}

resource "libvirt_volume" "os_volume" {
  name = "os_volume-${count.index}"
  base_volume_id = "${libvirt_volume.stretch_base_image.id}"
  pool = "kube"
  size = 10737418240
  count = 3
}

resource "libvirt_domain" "domain" {
  name = "domain-${count.index}"
  memory = "4096"
  vcpu = 4
  disk {
    volume_id = element(libvirt_volume.os_volume.*.id, count.index)
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
  count = 3
}

output "ips" {
  value = libvirt_domain.domain.*.network_interface.0.addresses
}

# Use CloudInit to add our ssh-keys
resource "libvirt_cloudinit_disk" "cloudinit_image" {
  name           = "cloudinit_image.iso"
  pool = "kube"
  user_data = <<EOF
#cloud-config
disable_root: 0
ssh_pwauth: 1
users:
  - name: root
    ssh-authorized-keys:
      - ${file("/home/jdg/.ssh/id_rsa.pub")}
  - name: debian
    ssh-authorized-keys:
      - ${file("/home/jdg/.ssh/id_rsa.pub")}
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    groups: wheel
growpart:
  mode: auto
  devices: ['/']
EOF
}

terraform {
  required_version = ">= 0.12"
}

