dnf update -y
# firewall-cmd --permanent --zone=public --add-port=9090/tcp
dnf install perl wget curl vim nc net-tools cloud-init ca-certificates git unzip -y
update-ca-trust
vmware-toolbox-cmd config set deployPkg enable-customization true
vmware-toolbox-cmd config set deployPkg enable-custom-scripts true
