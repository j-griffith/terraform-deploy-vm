#!/bin/bash
sudo virsh undefine kube-0
sudo virsh undefine kube-1
sudo virsh undefine kube-2

sudo virsh destroy kube-0
sudo virsh destroy kube-1
sudo virsh destroy kube-2

sudo virsh pool-destroy kube
sudo virsh pool-undefine kube
sudo rm -rf /tmp/kube
sudo rm /var/lib/libvirt/dnsmasq/virbr0.*

rm -rf .terraform terraform.tfstate*
