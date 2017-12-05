#!/usr/bin/ruby

require 'yaml'
require 'net/http'
require 'uri'
require 'socket'

#secrets_definition = YAML.load_file('secrets/secrets.yaml')
#registry = secrets_definition['registry']

###########################################################################
#                           VAGRANT BOX ADD
###########################################################################
#
# vagrant box add -name ocp36 ocp36.box
#
###########################################################################
#                                URLs
###########################################################################
#
# OpenShift console on: https://127.0.0.1:8443/console
# Apps on: curl -H "Host: app-project.dev.localdomain" http://127.0.0.1:8080
#
###########################################################################
#                              VARIABLES
###########################################################################

NODE_COUNT = 0
DISABLE_SHARED_FOLDER = true
BLOCK_DOCKER_IO = false
OCP_CPU = 2
OCP_MEMORY = 2048


###########################################################################

Vagrant.require_version ">= 1.9.2"
Vagrant.configure("2") do |config|

  config.vm.box = "ocp36"
  # config.vm.box_url = 'http://localhost:8000/ocp36.box'
  config.vm.box_check_update = false
  config.ssh.pty = true
  config.ssh.insert_key = false

  config.vm.synced_folder ".", "/vagrant", disabled: DISABLE_SHARED_FOLDER
  config.vm.define "master" do |master|
    # OCP console natting port
    master.vm.network "forwarded_port", guest: 8443, host: 8443
    # OCP router ports
    master.vm.network "forwarded_port", guest: 80, host: 8180
    master.vm.network "forwarded_port", guest: 443, host: 8043
    master.vm.hostname = "master.vagrant.local"
    master.vm.network "private_network", ip: "192.168.200.5",
      virtualbox__intnet: "OCP NETWORK"
    master.vm.provider "virtualbox" do |v, override|
      v.gui = false
      v.memory = OCP_MEMORY
      v.cpus   = OCP_CPU
      v.customize ["modifyvm", :id, "--ioapic", "on"]
      v.customize ["modifyvm", :id, "--nictype1", "virtio" ]
      v.customize ["modifyvm", :id, "--nictype2", "virtio" ]
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end

    master.vm.provision "shell", inline: <<-SHELL
      oc adm policy add-cluster-role-to-user cluster-admin admin
      sed -i "s/.*ADD_REGISTRY='--add-registry.*/ADD_REGISTRY='--add-registry registry.access.redhat.com'/g" /etc/sysconfig/docker
      systemctl restart docker
    SHELL


    if BLOCK_DOCKER_IO
      master.vm.provision "shell", inline: <<-SHELL
        sed -i "s/.*BLOCK_REGISTRY='--block-registry.*/BLOCK_REGISTRY='--block-registry docker.io'/g" /etc/sysconfig/docker
      SHELL
    end

  end

  NODE_COUNT.times do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{1}.vagrant.local"
      node.vm.network "private_network", ip: "192.168.200.5#{i}",
        virtualbox__intnet: "OCP NETWORK"

      node.vm.synced_folder ".", "/vagrant", disabled: true

      node.vm.provider "virtualbox" do |v, override|
        v.gui = false
        v.memory = OCP_MEMORY
        v.cpus   = OCP_CPU
        v.customize ["modifyvm", :id, "--ioapic", "on"]
        v.customize ["modifyvm", :id, "--nictype1", "virtio" ]
        v.customize ["modifyvm", :id, "--nictype2", "virtio" ]
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      end
      node.vm.provision "shell", inline: <<-SHELL
        systemctl stop etcd
        systemctl mask etcd
        systemctl stop atomic-openshift-master
        systemctl mask atomic-openshift-master
        systemctl stop openvswitch
        systemctl stop openvswitch-nonetwork.service
        systemctl stop atomic-openshift-node
        rm -rf /var/log/openvswitch
        rm -rf /etc/openvswitch/conf.db
        sed -i "s/nodeName.*/nodeName: $(ip -4 addr show eth1 | grep -Po 'inet \\K[\\d.]+')/g" /etc/origin/node/node-config.yaml
        oc adm ca create-server-cert --hostnames=[10.0.2.15,$(ip -4 addr show eth1 | grep -Po 'inet \\K[\\d.]+'),127.0.0.1] \
                                     --cert=/etc/origin/node/server.crt --key=/etc/origin/node/server.key \
                                     --signer-cert=/etc/origin/master/ca.crt --signer-key=/etc/origin/master/ca.key --signer-serial=/etc/origin/master/ca.serial.txt
        sed -i "s/.*ADD_REGISTRY='--add-registry.*/ADD_REGISTRY='--add-registry registry.access.redhat.com'/g" /etc/sysconfig/docker
        systemctl restart docker
        systemctl start atomic-openshift-node
        oc label node $(ip -4 addr show eth1 | grep -Po 'inet \\K[\\d.]+') region=primary zone=default
        systemctl stop docker
        rm -rf /var/lib/docker
        sleep 5
        systemctl start docker
        sleep 3

	    # Pull OCP images in advance, to speed up app deployment :)
        #OCP_IMAGE_VERSION=$(oc version | head  -1 | cut -d' ' -f2)
        #docker pull registry.access.redhat.com/openshift3/ose-haproxy-router:"$OCP_IMAGE_VERSION" &
        #docker pull registry.access.redhat.com/openshift3/ose-deployer:"$OCP_IMAGE_VERSION" &
        #docker pull registry.access.redhat.com/openshift3/ose-pod:"$OCP_IMAGE_VERSION" &
      SHELL

      if BLOCK_DOCKER_IO
        node.vm.provision "shell", inline: <<-SHELL
          sed -i "s/.*BLOCK_REGISTRY='--block-registry.*/BLOCK_REGISTRY='--block-registry docker.io'/g" /etc/sysconfig/docker
        SHELL
      end

    end
  end
end
