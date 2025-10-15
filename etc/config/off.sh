#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

iptables -F
iptables -t nat  -F
iptables -t mangle -F
iptables -X

