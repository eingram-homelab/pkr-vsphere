#version=RHEL8
# Use graphical install
graphical

repo --name="AppStream" --baseurl=file:///run/install/sources/mount-0000-cdrom/AppStream

%packages
@^minimal-environment

%end

# Keyboard layouts
keyboard --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=ens192 --ipv6=auto --activate
network  --hostname=rhel-temp.local

# Use CDROM installation media
cdrom

# Run the Setup Agent on first boot
firstboot --enable

ignoredisk --only-use=sda
# Partition clearing information
clearpart --none --initlabel
# Disk partitioning information
part /boot/efi --fstype="efi" --ondisk=sda --size=600 --fsoptions="umask=0077,shortname=winnt"
part pv.111 --fstype="lvmpv" --ondisk=sda --size=59814
part /boot --fstype="xfs" --ondisk=sda --size=1024
volgroup rhel --pesize=4096 pv.111
logvol swap --fstype="swap" --size=2104 --name=swap --vgname=rhel
logvol / --fstype="xfs" --size=46968 --name=root --vgname=rhel
logvol /home --fstype="xfs" --size=10728 --name=home --vgname=rhel

# System timezone
timezone America/Los_Angeles --isUtc --ntpservers=2.rhel.pool.ntp.org,2.rhel.pool.ntp.org,2.rhel.pool.ntp.org,2.rhel.pool.ntp.org

# Root password
rootpw --iscrypted --allow-ssh ${password}

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%post
echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/01-permitrootlogin.conf
%end

# Reboot after installation
reboot