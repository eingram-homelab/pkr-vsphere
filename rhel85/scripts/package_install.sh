dnf update -y
dnf install cockpit -y
systemctl enable --now cockpit.socket
systemctl start cockpit
firewall-cmd --permanent --zone=public --add-port=9090/tcp
dnf install perl wget curl vim nano net-tools -y
