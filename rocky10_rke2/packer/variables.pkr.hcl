# Declared variables. 

variable "vsphere_template_name" {
  type = string
}

variable "vm_folder" {
  type    = string
  default = "${env("vm_folder")}"
}

variable "cpu_num" {
  type = number
}

variable "disk_size" {
  type = number
}

variable "mem_size" {
  type = number
}

variable "vcenter_server" {
  type    = string
  default = "${env("vcenter_server")}"
}

variable "vcenter_dc_name" {
  type    = string
  default = "${env("vcenter_dc_name")}"
}

variable "vcenter_cluster" {
  type    = string
  default = "${env("vcenter_cluster")}"
}

variable "vsphere_host" {
  type    = string
  default = "${env("vsphere_host")}"
}

variable "vcenter_datastore" {
  type    = string
  default = "${env("vcenter_datastore")}"
}

variable "vm_network" {
  type    = string
  default = "${env("vm_network")}"
}

variable "os_iso_path" {
  type = string
}

variable "vm_version" {
  description = "Defaults to most current VM hardware supported by vCenter."
  type        = number
}