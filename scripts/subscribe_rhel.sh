#!/bin/sh

subscription-manager register --activationkey="${ACTIVATIONKEY}" --org="${ORGANIZATION}"
subscription-manager repos --disable "*"
subscription-manager repos --enable="rhel-7-fast-datapath-rpms" --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-ose-${OCP_VERSION}-rpms"
yum clean all
