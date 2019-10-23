provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "builder" {
  name = "builder"
  type = "dir"
  path = "/home/jdg/pools/builder-pool"
}

resource "libvirt_volume" "os_image_builder" {
  name = "os_image_builder"
  pool = "builder"
  source = "http://10.117.253.42:8080/debian-9-openstack-amd64.qcow2"
}

resource "libvirt_volume" "disk_builder_resized" {
  name = "disk"
  base_volume_id = "${libvirt_volume.os_image_builder.id}"
  pool = "builder"
  size = 10737418240
}

# Use CloudInit to add our ssh-key to the instance
resource "libvirt_cloudinit_disk" "cloudinit_builder_resized" {
  name           = "cloudinit_builder_resized.iso"
  pool = "builder"
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

resource "libvirt_domain" "domain_builder_resized" {
  name = "doman_builder_resized"
  memory = "512"
  vcpu = 1

  cloudinit = "${libvirt_cloudinit_disk.cloudinit_builder_resized.id}"

  network_interface {
    network_name = "default"
    wait_for_lease = true
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

  disk {
       volume_id = "${libvirt_volume.disk_builder_resized.id}"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

output "ip" {
  value = "${libvirt_domain.domain_builder_resized.network_interface.0.addresses.0}"
}
