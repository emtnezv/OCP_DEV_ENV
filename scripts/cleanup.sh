#!/bin/bash

# Remove old kernels
/bin/package-cleanup -y --oldkernels --count=1

# Remove all user packer files
rm -rf /home/vagrant/*

# Cleaning up udev rules
/bin/rm -f /etc/udev/rules.d/70*

# Cleaning up tmp
/bin/rm -rf /tmp/*
/bin/rm -rf /var/tmp/*

# Clear audit log, wtmp, lastlog and grubby
/bin/cat /dev/null > /var/log/audit/audit.log
/bin/cat /dev/null > /var/log/wtmp
/bin/cat /dev/null > /var/log/lastlog
/bin/cat /dev/null > /var/log/grubby

# Remove log files from the VM
find /var/log -type f -exec rm -f {} \;

# Remove cache 
rm -rf /var/cache/*

# Remove openshift install folder
rm -rf /etc/install_openshift

# Cleanup HD
dd if=/dev/zero of=/zerofile.tmp
rm -rf /zerofile.tmp

# Remove history
rm -rf ~/.bash_history
history -c

sync

#sudo init 0
