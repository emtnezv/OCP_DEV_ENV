#!/bin/bash

# Variables
OCP_FULL_VERSION="-${OCP_VERSION}${OCP_MINOR_VERSION}"

# Install prerequisites
yum install -y atomic-openshift-utils${OCP_FULL_VERSION} openshift-ansible${OCP_FULL_VERSION} openshift-ansible-roles${OCP_FULL_VERSION} openshift-ansible-playbooks${OCP_FULL_VERSION} \
            ansible docker atomic-openshift-excluder atomic-openshift-docker-excluder

atomic-openshift-excluder unexclude

# Configure docker storage
cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/sdb
VG=docker-vg
EOF
# docker-storage-setup

# Configure internal network
cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE=eth1
BOOTPROTO=static
ONBOOT=yes
PREFIX=24
IPADDR=192.168.200.5
EOF
nmcli connection reload
systemctl restart NetworkManager.service


# Open OCP router ports
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
iptables-save > /etc/sysconfig/iptables

# Install OCP
ansible-playbook -vvv -i /tmp/os_inventory_ocp.yml /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml

# Allow "get nodes" to anonymous users
ROLE_GET_NODES=$(cat <<EOF
{
    "kind": "ClusterRole",
    "apiVersion": "v1",
    "metadata": {
        "name": "get_nodes"
    },
    "rules": [
        {
            "verbs": [
                "get",
                "list"
            ],
            "resources": [
                "nodes"
            ]
        }
    ]
}
EOF
)

BINDING_GET_NODES=$(cat <<EOF
{
    "kind": "ClusterRoleBinding",
    "apiVersion": "v1",
    "metadata": {
        "name": "get_nodes"
    },
    "subjects": [
        {
            "kind": "SystemUser",
            "name": "system:anonymous"
        }
    ],
    "roleRef": {
        "name": "get_nodes"
    }
}
EOF
)

echo $ROLE_GET_NODES
echo $ROLE_GET_NODES | sudo oc create -f -
echo $BINDING_GET_NODES
echo $BINDING_GET_NODES | sudo oc create -f -
