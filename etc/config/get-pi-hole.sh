#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

git clone --depth 1 https://github.com/pi-hole/pi-hole.git pi-hole
