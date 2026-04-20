# Change this line to trigger new build

packer {
  required_plugins {
    vsphere = {
      source  = "github.com/hashicorp/vsphere"
      version = "~> 1"
    }
  }
}

local "vsphere_user" {
  expression = vault("/secret/vsphere/vcsa", "vsphere_username")
  sensitive  = true
}

local "vsphere_password" {
  expression = vault("/secret/vsphere/vcsa", "vsphere_password")
  sensitive  = true
}

local "encrypted_password" {
  expression = vault("/secret/ssh/eingram", "encrypted_password")
  sensitive  = true
}

local "ssh_password" {
  expression = vault("/secret/ssh/eingram", "ssh_password")
  sensitive  = true
}

# locals {
#   data_source_content = {
#     "/ks.cfg" = templatefile("${abspath(path.root)}/data/ks.pkrtpl.hcl", {
#       password = local.encrypted_password
#     })
#   }
# }

build {
  sources = ["source.vsphere-iso.ubuntu"]

  # Copy root ca cert to VM
  provisioner "file" {
    source      = "${abspath(path.root)}/data/homelab_ca.crt"
    destination = "/etc/pki/ca-trust/source/anchors/homelab_ca.crt"
  }

  # Upload and execute scripts using Shell
  provisioner "shell" {
    # execute_command = "echo 'temppassword' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'" # This runs the scripts with sudo
    scripts = [
      "${abspath(path.root)}/scripts/env_setup.sh",
      "${abspath(path.root)}/scripts/sysprep-op-bash-history.sh",
      "${abspath(path.root)}/scripts/sysprep-op-crash-data.sh",
      "${abspath(path.root)}/scripts/sysprep-op-dhcp-client-state.sh",
      #      "${abspath(path.root)}/scripts/sysprep-op-logfiles.sh",
      "${abspath(path.root)}/scripts/sysprep-op-machine-id.sh",
      "${abspath(path.root)}/scripts/sysprep-op-package-manager-cache.sh",
      "${abspath(path.root)}/scripts/sysprep-op-rpm-db.sh",
      "${abspath(path.root)}/scripts/sysprep-op-ssh-hostkeys.sh",
      #      "${abspath(path.root)}/scripts/sysprep-op-tmp-files.sh",
      "${abspath(path.root)}/scripts/sysprep-op-yum-uuid.sh"
    ]
  }

  # Output build details including artifact ID
  post-processor "manifest" {
    output     = "${abspath(path.root)}/build-manifest.json"
    strip_path = true
    custom_data = {
      build_timestamp = "${formatdate("YYYY-MM-DD hh:mm:ss", timestamp())}"
      vm_name         = "${var.vsphere_template_name}__${formatdate("YYYYMMDDHHmmss", timestamp())}"
      os_version      = "ubuntu Linux 9"
    }
  }
}

# Builder configuration, responsible for VM provisioning.

source "vsphere-iso" "ubuntu" {

  # vCenter parameters
  insecure_connection = "true"
  username            = "${local.vsphere_user}"
  password            = "${local.vsphere_password}"
  vcenter_server      = "${var.vcenter_server}"
  cluster             = "${var.vcenter_cluster}"
  datacenter          = "${var.vcenter_dc_name}"
  host                = "${var.vsphere_host}"
  datastore           = "${var.vcenter_datastore}"
  folder              = "${var.vm_folder}"
  vm_name             = "${var.vsphere_template_name}__${formatdate("YYYYMMDDHHmmss", timestamp())}"
  vm_version          = var.vm_version
  firmware            = "efi"
  convert_to_template = true

  # VM resource parameters 
  guest_os_type   = "rhel9_64Guest"
  CPUs            = "${var.cpu_num}"
  CPU_hot_plug    = true
  RAM             = "${var.mem_size}"
  RAM_hot_plug    = true
  RAM_reserve_all = false
  notes           = "Packer build ${formatdate("YYYYMMDDHHmmss", timestamp())}."

  network_adapters {
    network      = "${var.vm_network}"
    network_card = "vmxnet3"
  }

  disk_controller_type = ["pvscsi"]
  storage {
    disk_thin_provisioned = "true"
    disk_size             = var.disk_size
  }

  iso_paths = [
    "${var.os_iso_path}"
  ]

  # ubuntu OS parameters
  boot_order   = "disk,cdrom,floppy"
  boot_wait    = "10s"
  ssh_password = "temppassword"
  ssh_username = "root"

  #http_ip = "${var.builder_ipv4}"
  # http_directory = "/"
  # http_content = local.data_source_content
  boot_command = [
    "<up>e<wait><down><wait><down><wait><end> inst.text inst.ks=http://kickstart.local.lan/ks-ubuntu9.cfg<wait><leftCtrlOn>x<leftCtrlOff><wait>"
  ]
}

