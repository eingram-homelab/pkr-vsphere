#!/usr/bin/env bash

dnf update -y
# firewall-cmd --permanent --zone=public --add-port=9090/tcp
dnf install perl wget curl vim nc net-tools git unzip ca-certificates cloud-init -y
update-ca-trust
vmware-toolbox-cmd config set deployPkg enable-customization true
vmware-toolbox-cmd config set deployPkg enable-custom-scripts true
systemctl disable firewalld --now

