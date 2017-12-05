#!/bin/bash
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
EOF

# Upgrade OS
yum upgrade -y

yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion atomic-openshift-clients yum-utils

# Install EPEL repo to be able to install dkms rpm.
rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
