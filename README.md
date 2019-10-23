# This is a guide to setup a test environment for baremetal

## Install KVM/Libvirt and friends on your host(s)

Double check that `security_driver = "none"` is uncommented in `/etc/libvirt/qemu.conf`

## Terraform

```
wget https://releases.hashicorp.com/terraform/0.12.12/terraform_0.12.12_linux_amd64.zip
unzip terraform_0.12.12_linux_amd64.zip
sudo mv terraform ~/.local/bin/
```

## Terraform Libvirt provider

```
wget https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.0/terraform-provider-libvirt-0.6.0+git.1569597268.1c8597df.Ubuntu_18.04.amd64.tar.gz
gunzip terraform-provider-libvirt-0.6.0+git.1569597268.1c8597df.Ubuntu_18.04.amd64.tar.gz
tar -xvf terraform-provider-libvirt-0.6.0+git.1569597268.1c8597df.Ubuntu_18.04.amd64.tar
```

Create a terraform plugins directory and place the libvirt provider binary  there

```
mkdir -p ~/.terraform.d/plugins
cp terraform-provider-libvirt ~/.terraform.d/plugins/
```

## Give it a whirl

`terraform init && terraform plan && terraform apply`


Using the providing example (modify to suite your needs, including custom image with kubeadm pre-installed)

```
cd deploy-vm
terraform init && terraform plan && terraform apply
```

If/when things go south :)
Issue a `terraform destroy`

This isn't everything though, you'll want to manually ensure all of your resources are cleaned up:
* `rm -rf <path-to-storage-pool>`
* `virsh pool-undefine <pool-name>`
* `virsh pool-destroy <pool-name>`
* `virsh undefine <vm-name>`
* `virsh destroy <vm-name>`

Now, you can delete the tfstate files and try again: `rm -rf .terraform terraform.tfstate`

* You can update VCPU, Memor etc, just modify your tf file, run `terraform plan && terrform apply`
* To get your IP check out `sudo virsh net-dhcp-lease default`
