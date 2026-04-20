/* 
Specify any declared variables from the file of, variables.pkr.hcl, to override default values.
Example of default value of var cpu_name is 2 cores. We override that with 4 cores below.
*/

os_username = "administrator"
os_password = "temppassword"

vcenter_folder     = "Templates"
vcenter_server     = "vcsa-1.local.lan"
vcenter_datacenter = "HomeLab Datacenter"
vcenter_cluster    = "Intel NUC10 Cluster"
vcenter_host       = "esxinuc1.local.lan"
vcenter_datastore  = "esxinuc1:datastore1"

vm_name    = "TMP-Win10_Packer"
vm_network = "DPG-Lab-LAN1"

vm_guest_os_type = "windows9_64Guest" # Refer to https://code.vmware.com/apis/704/vcenter/vim.vm.GuestOsDescriptor.GuestOsIdentifier.html for guest OS types.
vm_version       = "20"               # Refer to https://kb.vmware.com/s/article/1003746 for specific VM versions.

os_iso_path      = "[esxinuc1:datastore1] Repo/Win10_22H2_English_x64.iso"
vmtools_iso_path = "[esxinuc1:datastore1] Repo/windows.iso"
floppy_img_path  = "[esxinuc1:datastore1] Repo/pvscsi-Windows8.flp"

cpu_num   = 4
ram       = 4096
disk_size = 40960