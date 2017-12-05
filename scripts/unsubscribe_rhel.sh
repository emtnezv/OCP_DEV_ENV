#!/bin/bash

# Cleanup subscription-manager
yum clean all
subscription-manager remove --all
subscription-manager unregister
subscription-manager clean