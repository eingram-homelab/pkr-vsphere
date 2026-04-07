# Assign values to override their default values (default values are found in the vsphere_centos8.pkr.hcl file).
# All values are automatically used and persist through the entire Packer process.

vsphere_template_name = "TMP-Ubuntu24_Packer"
vm_folder             = "Templates"

cpu_num   = 4
mem_size  = 4096
disk_size = 61450

vcenter_server    = "vcsa-1.local.lan"
vcenter_dc_name   = "HomeLab Datacenter"
vcenter_cluster   = "Intel NUC10 Cluster"
vsphere_host      = "esxinuc1.local.lan"
vcenter_datastore = "esxinuc1:datastore1"
vm_network        = "DPG-Lab-LAN1"

os_iso_path = "[esxinuc1:datastore1] Repo/Rocky-9.5-x86_64-dvd.iso"
vm_version  = "20"

